// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beto_common/beto_common.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'benchmark_data_store.dart';
import 'logging.dart';
import 'middleware.dart';
import 'service.dart';
import 'service_handler.dart';

enum DataStore {
  inMemory,
  bigQuery,
}

class BetoServer {
  BetoServer({
    this.port,
    this.address,
    this.logRequests = false,
    this.useRequestCounter = false,
    this.googleServiceAccountCredentialsPath = 'service-account.json',
    this.dataStore = DataStore.bigQuery,
  });

  static const _googleCloudScopes = [BigqueryApi.bigqueryScope];

  final int? port;
  final InternetAddress? address;
  final bool logRequests;
  final bool useRequestCounter;
  final String googleServiceAccountCredentialsPath;
  final DataStore dataStore;

  int get _port => port ?? 0;
  InternetAddress get _address => address ?? InternetAddress.loopbackIPv4;

  late final _httpClient = _createHttpClient();
  late final _googleCloudClient = _createGoogleCloudClient();
  late final _benchmarkDataStore = _createBenchmarkDataStore();
  late final _betoService = _createBetoService();

  late HttpServer _server;

  final _onStopActions = <FutureOr<void> Function()>[];

  void _onStop(FutureOr<void> Function() action) {
    _onStopActions.add(action);
  }

  Future<void> start() async {
    final handler = _createHandler(await _betoService);

    final server = _server = await shelf_io.serve(
      handler,
      _address,
      _port,
      poweredByHeader: null,
    );
    // ignore: cascade_invocations
    server.autoCompress = true;

    _onStop(server.close);

    logger.info('Listening on http://${_server.address.host}:${_server.port}');
  }

  shelf.Handler _createHandler(BetoService service) {
    var pipeline = const shelf.Pipeline()
        .addMiddleware(requestId(useRequestCounter: useRequestCounter));
    if (logRequests) {
      pipeline = pipeline.addMiddleware(shelf.logRequests());
    }
    pipeline = pipeline
        .addMiddleware(jsonBody())
        .addMiddleware(httpExceptionHandling());

    return pipeline.addHandler(betoServiceHandler(service));
  }

  Client _createHttpClient() {
    final client = Client();
    _onStop(client.close);
    return client;
  }

  Future<AuthClient> _createGoogleCloudClient() async {
    var googleCloudCredentials =
        await _obtainAccessCredentialsViaServiceAccountFile();

    try {
      googleCloudCredentials ??=
          await obtainAccessCredentialsViaMetadataServer(_httpClient);
    } catch (e) {
      throw InvalidConfiguration(
        'Unable to obtain Google Cloud credentials. '
        'Please provide a service account file or run in a Google Cloud '
        'environment.\nError: $e',
      );
    }

    final googleCloudClient =
        authenticatedClient(_httpClient, googleCloudCredentials);
    _onStop(googleCloudClient.close);

    return googleCloudClient;
  }

  Future<AccessCredentials?>
      _obtainAccessCredentialsViaServiceAccountFile() async {
    final credentialsFile = File(googleServiceAccountCredentialsPath);
    if (!credentialsFile.existsSync()) {
      return null;
    }

    final credentialsString = await credentialsFile.readAsString();
    ServiceAccountCredentials credentials;
    try {
      credentials =
          ServiceAccountCredentials.fromJson(jsonDecode(credentialsString));
    } catch (e) {
      throw InvalidConfiguration('Invalid service account credentials:\n$e.');
    }
    return obtainAccessCredentialsViaServiceAccount(
      credentials,
      _googleCloudScopes,
      _httpClient,
    );
  }

  Future<BenchmarkDataStore> _createBenchmarkDataStore() async {
    switch (dataStore) {
      case DataStore.inMemory:
        return InMemoryBenchmarkDataStore();
      case DataStore.bigQuery:
        final bigQueryApi = BigqueryApi(await _googleCloudClient);
        final benchmarkDataStore =
            BigQueryBenchmarkDataStore(bigQueryApi: bigQueryApi);
        await benchmarkDataStore.initialize();
        return benchmarkDataStore;
    }
  }

  Future<BetoServiceImpl> _createBetoService() async =>
      BetoServiceImpl(benchmarkDataStore: await _benchmarkDataStore);

  Future<void> stop() async {
    logger.info('Stopping server...');
    for (final action in _onStopActions) {
      await action();
    }
  }
}

class InvalidConfiguration implements Exception {
  InvalidConfiguration(this.message);

  final String message;

  @override
  String toString() => 'InvalidConfiguration: $message';
}
