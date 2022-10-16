import 'package:googleapis/bigquery/v2.dart';

abstract class BenchmarkDataStore {}

class InMemoryBenchmarkDataStore extends BenchmarkDataStore {}

class BigQueryBenchmarkDataStore extends BenchmarkDataStore {
  BigQueryBenchmarkDataStore({
    required this.bigQueryApi,
  });

  final BigqueryApi bigQueryApi;

  Future<void> initialize() async {}
}
