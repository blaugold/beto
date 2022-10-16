// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_catches_without_on_clauses, avoid_dynamic_calls, empty_catches

import 'dart:convert';
import 'dart:io';

import 'package:beto_common/beto_common.dart';
import 'package:shelf/shelf.dart';

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
        } catch (e) {
          // TODO: Logging
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
      } catch (e) {
        // TODO: Logging
      }
    } else {
      // TODO: Logging
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
