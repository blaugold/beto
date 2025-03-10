import 'dart:async';

import 'package:beto_common/beto_common.dart';
import 'package:beto_server/src/logging.dart';
import 'package:beto_server/src/services.dart';
import 'package:beto_server/src/storage/benchmark_data_store.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

final bigQueryServices = Services(
  gcpServiceAccount: 'test-service-account.json',
  bigQueryDatasetId: 'test_${DateTime.now().millisecondsSinceEpoch}',
  // ignore: avoid_redundant_argument_values
  benchmarkDataStoreType: BenchmarkDataStoreType.bigQuery,
);

final inMemoryServices = Services(
  benchmarkDataStoreType: BenchmarkDataStoreType.inMemory,
);

void main() {
  setUpAll(() {
    setupLogging(logLevel: Level.INFO);
  });

  tearDownAll(() async {
    await bigQueryServices
        .deleteBigQueryDataset(bigQueryServices.bigQueryDatasetId);
    await bigQueryServices.dispose();
    await inMemoryServices.dispose();
  });

  benchmarkStoreTest('query', () async {
    final dataStore = await getBenchmarkDataStore();
    final record = BenchmarkRecord(
      startTime: DateTime.now(),
      commit: 'test',
      environment: Environment.current(device: 'test'),
      suites: [
        Suite(
          name: 'a',
          benchmarks: [
            Benchmark(
              name: 'a',
              metrics: [
                Metric(
                  name: 'a',
                  values: [
                    Value(
                      statistic: Statistic.count,
                      value: 0,
                      parameters: {'a': 'aa'},
                    ),
                  ],
                ),
              ],
            ),
            Benchmark(
              name: 'b',
              metrics: [
                Metric(
                  name: 'b',
                  values: [
                    Value(
                      statistic: Statistic.count,
                      value: 0,
                      parameters: {'b': 'bb'},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await dataStore.insertBenchmarkRecord(record);

    final resultRecords = await dataStore.queryBenchmarkRecords(
      suite: 'a',
      benchmark: 'a',
      device: 'test',
      range: CommitRange('test'),
    );

    expect(resultRecords, hasLength(1));
    final resultRecord = resultRecords.first;
    expect(resultRecord.suites, hasLength(1));
    final resultSuite = resultRecord.suites.first;
    expect(resultSuite.name, 'a');
    expect(resultSuite.benchmarks, hasLength(1));
    final resultBenchmark = resultSuite.benchmarks.first;
    expect(resultBenchmark.name, 'a');
    expect(resultBenchmark.metrics, hasLength(1));
    final resultMetric = resultBenchmark.metrics.first;
    expect(resultMetric.name, 'a');
    expect(resultMetric.values, hasLength(1));
    final resultValue = resultMetric.values.first;
    expect(resultValue.parameters, {'a': 'aa'});
  });
}

typedef GetBenchmarkDataStore = Future<BenchmarkDataStore> Function();

GetBenchmarkDataStore get getBenchmarkDataStore =>
    Zone.current[#getBenchmarkDataStore] as GetBenchmarkDataStore;

@isTestGroup
void benchmarkStoreTest(String name, FutureOr<void> Function() body) {
  group(name, () {
    test(
      'InMemory',
      () async => await runZoned(
        body,
        zoneValues: {
          #getBenchmarkDataStore: () async =>
              inMemoryServices.benchmarkDataStore,
        },
      ),
    );

    test(
      'BigQuery',
      () async => await runZoned(
        body,
        zoneValues: {
          #getBenchmarkDataStore: () async =>
              bigQueryServices.benchmarkDataStore,
        },
      ),
    );
  });
}

extension on Services {
  Future<void> deleteBigQueryDataset(String datasetId) async {
    final bigQueryApi = await this.bigQueryApi;
    try {
      await bigQueryApi.datasets.delete(
        await googleCloudProjectId,
        datasetId,
        deleteContents: true,
      );
    } on DetailedApiRequestError catch (e) {
      if (e.status != 404) {
        rethrow;
      }
    }
  }
}
