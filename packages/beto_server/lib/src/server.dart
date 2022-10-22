// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';
import 'dart:io';

import 'package:beto_common/beto_common.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'authentication.dart';
import 'configuration.dart';
import 'logging.dart';
import 'middleware.dart';
import 'service_handler.dart';
import 'services.dart';

final _port = IntegerOption(
  name: 'port',
  description: 'The port to listen on. When set to 0, a random port will be '
      'selected.',
  defaultValue: 8080,
  abbreviation: 'p',
);

final _address = InternetAddressOption(
  name: 'address',
  description: 'The address to listen on.',
  defaultValue: InternetAddress.anyIPv4,
  abbreviation: 'a',
);

final _logRequests = FlagOption(
  name: 'logRequest',
  description: 'Whether to log requests.',
  defaultValue: false,
);

final _useRequestCounter = FlagOption(
  name: 'useRequestCounter',
  description:
      'Whether to use a request counter to generate request IDs instead of '
      'using a UUID.',
  defaultValue: false,
);

final _apiSecrets = ListOption<String>(
  option: StringOption(
    name: 'apiSecrets',
    description: 'The API secrets to use for authentication.',
  ),
  defaultValue: [],
);

final List<Option> serverOptions = [
  _port,
  _address,
  _logRequests,
  _useRequestCounter,
  _apiSecrets,
];

extension ServerOptions on Options {
  int get port => get(_port);
  InternetAddress get address => get(_address);
  bool get logRequests => get(_logRequests);
  bool get useRequestCounter => get(_useRequestCounter);
  List<String> get apiSecrets => get(_apiSecrets);
}

class BetoServer {
  BetoServer({
    this.port,
    this.address,
    this.logRequests = false,
    this.useRequestCounter = false,
    this.apiSecrets = const [],
    required this.services,
  });

  final int? port;
  final InternetAddress? address;
  final bool logRequests;
  final bool useRequestCounter;
  final List<String> apiSecrets;
  final Services services;

  int get actualPort => _server.port;
  InternetAddress get actualAddress => _server.address;

  int get _port => port ?? 0;
  InternetAddress get _address => address ?? InternetAddress.loopbackIPv4;

  late HttpServer _server;

  Future<void> start() async {
    final handler = _createHandler(await services.betoService);

    final server = _server = await shelf_io.serve(
      handler,
      _address,
      _port,
      poweredByHeader: null,
    );
    // ignore: cascade_invocations
    server.autoCompress = true;

    logger.info('Listening on http://${_server.address.host}:${_server.port}');
  }

  shelf.Handler _createHandler(BetoService service) {
    var pipeline = const shelf.Pipeline()
        .addMiddleware(requestId(useRequestCounter: useRequestCounter))
        .addMiddleware(authentication(_createAuthenticationProvider()));
    if (logRequests) {
      pipeline = pipeline.addMiddleware(shelf.logRequests());
    }
    pipeline = pipeline
        .addMiddleware(jsonBody())
        .addMiddleware(httpExceptionHandling());

    return pipeline.addHandler(betoServiceHandler(service));
  }

  AuthenticationProvider _createAuthenticationProvider() =>
      DelegatingAuthenticationProvider(
        resolvers: [
          SecretAuthenticationResolver(),
        ],
        authorizers: [
          SecretsAuthorizer(apiSecrets),
        ],
      );

  Future<void> stop() async {
    logger.info('Stopping server...');
    await _server.close();
  }
}
