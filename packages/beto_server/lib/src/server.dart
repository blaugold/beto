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

class BetoServer {
  BetoServer({
    this.port,
    this.address,
    this.logRequests = false,
    this.useRequestCounter = false,
    this.apiSecrets = const [],
    this.googleCloudServiceAccountJsonPath = 'service-account.json',
    this.bigQueryDatasetId = 'beto_benchmark_data',
    this.dataStoreImpl = DataStoreImpl.bigQuery,
  });

  final int? port;
  final InternetAddress? address;
  final bool logRequests;
  final bool useRequestCounter;
  final List<String> apiSecrets;
  final String googleCloudServiceAccountJsonPath;
  final String bigQueryDatasetId;
  final DataStoreImpl dataStoreImpl;

  int get actualPort => _server.port;
  InternetAddress get actualAddress => _server.address;

  late final _configuration = Configuration(
    bigQueryDatasetId: bigQueryDatasetId,
    dataStoreImpl: dataStoreImpl,
    googleCloudServiceAccountJsonPath: googleCloudServiceAccountJsonPath,
  );

  int get _port => port ?? 0;
  InternetAddress get _address => address ?? InternetAddress.loopbackIPv4;

  late HttpServer _server;

  Future<void> start() async {
    final handler = _createHandler(await _configuration.betoService);

    final server = _server = await shelf_io.serve(
      handler,
      _address,
      _port,
      poweredByHeader: null,
    );
    // ignore: cascade_invocations
    server.autoCompress = true;

    _configuration.addDisposeAction(server.close);

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
    await _configuration.dispose();
  }
}
