import 'package:beto_common/beto_common.dart';

abstract class BenchmarkDataStore {
  Future<void> initialize() async {}

  Future<void> dispose() async {}

  Future<void> insertBenchmarkRecord(BenchmarkRecord record);

  Future<List<BenchmarkRecord>> queryBenchmarkRecords({
    required String suite,
    required String benchmark,
    required String device,
    required BenchmarkDataRange range,
  });
}
