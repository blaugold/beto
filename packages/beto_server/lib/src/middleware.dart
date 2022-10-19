// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_catches_without_on_clauses, avoid_dynamic_calls, empty_catches

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beto_common/beto_common.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import 'authentication.dart';
import 'logging.dart';

abstract class HttpException {
  int get statusCode;
}

Middleware httpExceptionHandling() => createMiddleware(
      errorHandler: (error, _) {
        if (error is HttpException) {
          String? body;
          Object? jsonBody;
          try {
            jsonBody = (error as dynamic).toJson();
          } catch (e) {}
          if (jsonBody != null) {
            body = json.encode(jsonBody);
          } else {
            body = error.toString();
          }
          return Response(error.statusCode, body: body);
        }
        // ignore: only_throw_errors
        throw error;
      },
    );

Middleware betoErrorHandling() => createMiddleware(
      errorHandler: (error, stackTrace) {
        if (error is BetoException) {
          return error.jsonResponse(error.statusCode);
        }
        // ignore: only_throw_errors
        throw error;
      },
    );

const _jsonBodyContextKey = 'beto_server.jsonBody';

Middleware jsonBody() {
  final jsonDecoder = utf8.decoder.fuse(json.decoder);
  final contentTypeJson = ContentType.json.toString();

  Handler decodingMiddleware(Handler innerHandler) => (request) async {
        if (request.headers[HttpHeaders.contentTypeHeader] != contentTypeJson) {
          return innerHandler(request);
        }

        final Object? body;
        try {
          body = await jsonDecoder.bind(request.read()).first;
        } catch (error, stackTrace) {
          logger.info('Received invalid JSON.', error, stackTrace);
          return Response.badRequest(body: 'Invalid JSON.');
        }

        final updatedRequest =
            request.change(context: {_jsonBodyContextKey: body});
        return innerHandler(updatedRequest);
      };

  Handler encodingMiddleware(Handler innerHandler) => (request) async {
        final response = await innerHandler(request);
        final jsonBody = response.context[_jsonBodyContextKey];
        if (jsonBody == null) {
          return response;
        }

        return response.change(
          context: {_jsonBodyContextKey: null},
          body: json.encode(jsonBody),
          headers: {
            HttpHeaders.contentTypeHeader: contentTypeJson,
          },
        );
      };

  return decodingMiddleware.addMiddleware(encodingMiddleware);
}

class _JsonBodyException implements Exception, HttpException {
  _JsonBodyException(this.message);

  @override
  int get statusCode => HttpStatus.badRequest;

  final String message;

  @override
  String toString() => message;
}

extension JsonBodyRequest on Request {
  bool get hasJsonBody => context.containsKey(_jsonBodyContextKey);

  Object? get jsonBody {
    if (!hasJsonBody) {
      throw _JsonBodyException('Expected a JSON body.');
    }
    return context[_jsonBodyContextKey];
  }

  R deserializeJson<R, T>(R Function(T) fromJson) {
    final body = jsonBody;

    if (body is T) {
      try {
        return fromJson(body);
      } catch (error, stackTrace) {
        logger.info(
          'Received JSON that could not be deserialized to $R.',
          error,
          stackTrace,
        );
      }
    } else {
      logger.info(
        'Received JSON body of unexpected type. '
        'Expected $T but got ${body.runtimeType}.',
      );
    }

    throw _JsonBodyException('Invalid data in JSON body.');
  }
}

extension JsonBodyResponse on Response {
  Response addJsonBody(Object? body) => change(
        context: {_jsonBodyContextKey: body},
      );
}

extension ObjectJsonBodyResponse on Object? {
  Response jsonResponse([int statusCode = 200]) =>
      Response(statusCode).addJsonBody(this);
}

const _requestIdContextKey = 'beto_server.requestId';

Middleware requestId({bool useRequestCounter = false}) {
  var requestCounter = 0;
  return (innerHandler) => (request) async {
        final String id;
        if (useRequestCounter) {
          id = (++requestCounter).toString();
        } else {
          id = const Uuid().v4();
        }

        final updatedRequest =
            request.change(context: {_requestIdContextKey: id});
        return runZoned(
          () => innerHandler(updatedRequest),
          zoneValues: {
            _requestIdContextKey: id,
          },
        );
      };
}

extension RequestIdRequest on Request {
  bool get hasRequestId => context.containsKey(_requestIdContextKey);

  String get requestId {
    final id = context[_requestIdContextKey];
    if (id is String) {
      return id;
    }
    throw StateError('requestId middleware is not installed.');
  }
}

extension ZoneRequestId on Zone {
  String? get requestId => this[_requestIdContextKey] as String?;
}

String? get currentRequestId => Zone.current.requestId;

const _authenticationContextKey = 'beto_server.authentication';

Middleware authentication(AuthenticationProvider authenticationProvider) =>
    (innerHandler) => (request) async {
          final authentication =
              await authenticationProvider.authenticate(request);
          final updatedRequest = request.change(
            context: {_authenticationContextKey: authentication},
          );
          return withAuthentication(
            authentication,
            () => innerHandler(updatedRequest),
          );
        };

extension RequestAuthentication on Request {
  bool get hasAuthentication => context.containsKey(_authenticationContextKey);

  Authentication get authentication {
    final authentication = context[_authenticationContextKey];
    if (authentication is Authentication) {
      return authentication;
    }
    throw StateError('authentication middleware is not installed.');
  }
}
