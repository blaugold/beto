import 'package:beto_client/beto_client.dart';
import 'package:beto_common/beto_common.dart';
import 'package:beto_server/beto_server.dart';
import 'package:beto_server/src/logging.dart';
import 'package:beto_server/src/services.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() => setupLogging(logLevel: Level.INFO));

  const apiSecretCredentials = ApiSecret('secret');

  final services = Services(
    benchmarkDataStoreType: BenchmarkDataStoreType.inMemory,
  );

  final server = BetoServer(
    apiSecrets: [apiSecretCredentials.apiSecret],
    logRequests: true,
    useRequestCounter: true,
    services: services,
  );

  late final serverUrl = Uri(
    scheme: 'http',
    host: server.actualAddress.address,
    port: server.actualPort,
  );

  setUpAll(server.start);
  tearDownAll(server.stop);
  tearDownAll(services.dispose);

  test('make request with unauthorized credentials', () async {
    final client = BetoServiceHttpClient(
      serverUrl: serverUrl,
      credentials: const ApiSecret('wrong'),
    );

    await expectLater(
      () => client.queryBenchmarkData(
        QueryBenchmarkDataRequest(
          suite: 'test',
          benchmark: 'test',
          device: 'test',
          range: CommitRange('test'),
        ),
      ),
      throwsA(
        isA<BetoException>().having((p0) => p0.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('submit and query benchmark data', () async {
    final client = BetoServiceHttpClient(
      serverUrl: serverUrl,
      credentials: apiSecretCredentials,
    );

    final record = BenchmarkRecord(
      startTime: DateTime.now(),
      commit: 'test',
      environment: Environment.current(device: 'test'),
      suites: [
        Suite(
          name: 'test',
          benchmarks: [
            Benchmark(
              name: 'test',
              metrics: [
                Metric(
                  name: 'test',
                  values: [
                    Value(
                      statistic: Statistic.count,
                      value: 0,
                      parameters: {'test': 'test'},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await client
        .submitBenchmarkData(SubmitBenchmarkDataRequest(record: record));

    final queriedRecords = await client.queryBenchmarkData(
      QueryBenchmarkDataRequest(
        suite: 'test',
        benchmark: 'test',
        device: 'test',
        range: CommitRange('test'),
      ),
    );
    expect(queriedRecords, hasLength(1));
    final queriedRecord = queriedRecords.first;
    expect(queriedRecord.id, record.id);
    expect(queriedRecord.suites, hasLength(1));
    final suite = queriedRecord.suites.first;
    expect(suite.name, 'test');
    expect(suite.benchmarks, hasLength(1));
    final benchmark = suite.benchmarks.first;
    expect(benchmark.name, 'test');
    expect(benchmark.metrics, hasLength(1));
    final metric = benchmark.metrics.first;
    expect(metric.name, 'test');
    expect(metric.values, hasLength(1));
    final value = metric.values.first;
    expect(value.statistic, Statistic.count);
    expect(value.value, 0);
    expect(value.parameters, {'test': 'test'});
  });
}
