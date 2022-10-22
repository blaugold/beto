// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import 'configuration.dart';
import 'service.dart';
import 'storage/benchmark_data_store.dart';
import 'storage/big_query_benchmark_data_store.dart';
import 'storage/in_memory_benchmark_data_store.dart';

final _gcpServiceAccount = StringOption(
  name: 'gcpServiceAccount',
  description: 'The path to the GCP service account JSON file to use '
      'when accessing GCP services.',
  defaultValue: 'service-account.json',
);

final _bigQueryDatasetId = StringOption(
  name: 'bigQueryDatasetId',
  description: 'The ID of the BigQuery dataset to store benchmark data in.',
  defaultValue: 'beto_benchmark_data',
);

final _benchmarkDataStore = EnumOption(
  name: 'benchmarkDataStore',
  description: 'The store to use for storing benchmark data.',
  allowedValues: BenchmarkDataStoreType.values,
  defaultValue: BenchmarkDataStoreType.bigQuery,
);

final List<Option> servicesOptions = [
  _gcpServiceAccount,
  _bigQueryDatasetId,
  _benchmarkDataStore,
];

extension ServicesOptions on Options {
  String get gcpServiceAccount => this.get(_gcpServiceAccount);
  String get bigQueryDatasetId => this.get(_bigQueryDatasetId);
  BenchmarkDataStoreType get benchmarkDataStore =>
      this.get(_benchmarkDataStore);
}

enum BenchmarkDataStoreType {
  inMemory,
  bigQuery,
}

class Services {
  Services({
    this.googleCloudServiceAccountJsonPath = 'service-account.json',
    this.bigQueryDatasetId = 'beto_benchmark_data',
    this.benchmarkDataStoreType = BenchmarkDataStoreType.bigQuery,
  });

  static const _googleCloudScopes = [BigqueryApi.bigqueryScope];
  static const _googleCloudProjectIdMetadataUrl =
      'http://metadata.google.internal/computeMetadata/v1/project/project-id';

  final String googleCloudServiceAccountJsonPath;
  final String bigQueryDatasetId;
  final BenchmarkDataStoreType benchmarkDataStoreType;

  late final httpClient = _createHttpClient();
  late final googleCloudServiceAccountJson = _loadServiceAccountJson();
  late final googleCloudProjectId = _loadProjectId();
  late final googleCloudClient = _createGoogleCloudClient();
  late final bigQueryApi = _createBigQueryApi();
  late final benchmarkDataStore = _createBenchmarkDataStore();
  late final betoService = _createBetoService();

  late final _googleCloudServiceAccountJsonExists =
      File(googleCloudServiceAccountJsonPath).existsSync();

  final _disposeActions = <FutureOr<void> Function()>[];

  void addDisposeAction(FutureOr<void> Function() action) {
    _disposeActions.add(action);
  }

  Future<void> dispose() async {
    for (final action in _disposeActions) {
      await action();
    }
  }

  Client _createHttpClient() {
    final client = Client();
    addDisposeAction(client.close);
    return client;
  }

  Future<Map<String, Object?>> _loadServiceAccountJson() async {
    final serviceAccountFile = File(googleCloudServiceAccountJsonPath);
    final serviceAccountJson = await serviceAccountFile.readAsString();
    return jsonDecode(serviceAccountJson) as Map<String, Object?>;
  }

  Future<String> _loadProjectId() async {
    if (_googleCloudServiceAccountJsonExists) {
      return (await googleCloudServiceAccountJson)['project_id']! as String;
    } else {
      return _obtainProjectIdFromMetadataServer();
    }
  }

  Future<AuthClient> _createGoogleCloudClient() async {
    final AccessCredentials googleCloudCredentials;

    if (_googleCloudServiceAccountJsonExists) {
      googleCloudCredentials =
          await _obtainAccessCredentialsViaServiceAccountFile();
    } else {
      try {
        googleCloudCredentials =
            await obtainAccessCredentialsViaMetadataServer(httpClient);
      } catch (e) {
        throw InvalidConfiguration(
          'Unable to obtain Google Cloud credentials. '
          'Please provide a service account file or run in a Google Cloud '
          'environment.\nError: $e',
        );
      }
    }

    final googleCloudClient =
        authenticatedClient(httpClient, googleCloudCredentials);
    addDisposeAction(googleCloudClient.close);

    return googleCloudClient;
  }

  Future<BigqueryApi> _createBigQueryApi() async =>
      BigqueryApi(await googleCloudClient);

  Future<AccessCredentials>
      _obtainAccessCredentialsViaServiceAccountFile() async {
    final credentialsString =
        await File(googleCloudServiceAccountJsonPath).readAsString();
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
      httpClient,
    );
  }

  Future<String> _obtainProjectIdFromMetadataServer() async {
    final response = await httpClient.get(
      Uri.parse(_googleCloudProjectIdMetadataUrl),
      headers: {
        'Metadata-Flavor': 'Google',
      },
    );
    if (response.statusCode != 200) {
      throw InvalidConfiguration(
        'Unable to obtain Google Cloud project ID from metadata server.\n'
        '${response.statusCode}: ${response.body}',
      );
    }
    return response.body;
  }

  Future<BenchmarkDataStore> _createBenchmarkDataStore() async {
    final BenchmarkDataStore store;
    switch (benchmarkDataStoreType) {
      case BenchmarkDataStoreType.inMemory:
        store = InMemoryBenchmarkDataStore();
        break;
      case BenchmarkDataStoreType.bigQuery:
        store = BigQueryBenchmarkDataStore(
          bigQueryApi: await bigQueryApi,
          projectId: await googleCloudProjectId,
          datasetId: bigQueryDatasetId,
        );
        break;
    }
    await store.initialize();
    addDisposeAction(store.dispose);
    return store;
  }

  Future<BetoServiceImpl> _createBetoService() async =>
      BetoServiceImpl(benchmarkDataStore: await benchmarkDataStore);
}
