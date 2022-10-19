import 'package:beto_common/beto_common.dart';

import 'storage/benchmark_data_store.dart';

class BetoServiceImpl extends BetoService {
  BetoServiceImpl({
    required this.benchmarkDataStore,
  });

  final BenchmarkDataStore benchmarkDataStore;

  @override
  Future<void> submitBenchmarkData(SubmitBenchmarkDataRequest request) async {
    await benchmarkDataStore.insertBenchmarkRecord(request.record);
  }

  @override
  Future<List<BenchmarkRecord>> queryBenchmarkData(
    QueryBenchmarkDataRequest request,
  ) =>
      benchmarkDataStore.queryBenchmarkRecords(
        suite: request.suite,
        benchmark: request.benchmark,
        device: request.device,
        range: request.range,
      );
}
