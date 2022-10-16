import 'package:beto_common/beto_common.dart';

import 'benchmark_data_store.dart';

class BetoServiceImpl extends BetoService {
  BetoServiceImpl({
    required this.benchmarkDataStore,
  });

  final BenchmarkDataStore benchmarkDataStore;

  @override
  Future<void> submitBenchmarkData(SubmitBenchmarkDataRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<List<Suite>> queryBenchmarkData(QueryBenchmarkDataRequest request) {
    throw UnimplementedError();
  }
}
