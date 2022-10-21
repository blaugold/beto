import 'package:beto_common/beto_common.dart';

import 'benchmark_data_store.dart';

class InMemoryBenchmarkDataStore extends BenchmarkDataStore {
  final _records = <BenchmarkRecord>[];

  @override
  Future<void> insertBenchmarkRecord(BenchmarkRecord record) async {
    _records.add(record);
    _sortRecords();
  }

  @override
  Future<List<BenchmarkRecord>> queryBenchmarkRecords({
    required String suite,
    required String benchmark,
    required String device,
    required BenchmarkDataRange range,
  }) async =>
      _findRecordsInRange(range)
          .where((record) => record.environment.device == device)
          .map((record) => _filterRecordData(record, suite, benchmark))
          .whereType<BenchmarkRecord>()
          .toList();

  void _sortRecords() {
    _records.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<BenchmarkRecord> _findRecordsInRange(BenchmarkDataRange range) {
    if (range is CommitRange) {
      return _records.where((record) => record.commit == range.commit).toList();
    } else if (range is DateRange) {
      return _records
          .where(
            (record) =>
                record.startTime.compareTo(range.start) >= 0 &&
                record.startTime.compareTo(range.end) <= 0,
          )
          .toList();
    } else {
      throw UnimplementedError(
        'Range type ${range.runtimeType} not implemented.',
      );
    }
  }
}

BenchmarkRecord? _filterRecordData(
  BenchmarkRecord record,
  String suiteName,
  String benchmarkName,
) {
  final filteredRecord = BenchmarkRecord(
    id: record.id,
    startTime: record.startTime,
    commit: record.commit,
    environment: record.environment,
  );
  var filteredRecordIsEmpty = true;

  for (final suite in record.suites) {
    if (suite.name == suiteName) {
      final filteredSuite = Suite(name: suite.name);
      filteredRecord.addSuite(filteredSuite);

      for (final benchmark in suite.benchmarks) {
        if (benchmark.name == benchmarkName) {
          filteredRecordIsEmpty = false;
          filteredSuite.addBenchmark(benchmark.clone());
        }
      }
    }
  }

  return filteredRecordIsEmpty ? null : filteredRecord;
}
