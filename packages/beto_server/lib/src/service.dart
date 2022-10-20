import 'dart:async';

import 'package:beto_common/beto_common.dart';

import 'authentication.dart';
import 'storage/benchmark_data_store.dart';

class BetoServiceImpl extends BetoService {
  BetoServiceImpl({
    required this.benchmarkDataStore,
  });

  final BenchmarkDataStore benchmarkDataStore;

  @override
  Future<void> submitBenchmarkData(SubmitBenchmarkDataRequest request) async {
    _requireAuthentication();
    await benchmarkDataStore.insertBenchmarkRecord(request.record);
  }

  @override
  Future<List<BenchmarkRecord>> queryBenchmarkData(
    QueryBenchmarkDataRequest request,
  ) {
    _requireAuthentication();
    return benchmarkDataStore.queryBenchmarkRecords(
      suite: request.suite,
      benchmark: request.benchmark,
      device: request.device,
      range: request.range,
    );
  }

  void _requireAuthentication() {
    if (currentAuthentication?.isAuthenticated != true) {
      throw BetoException(
        statusCode: 401,
        message: 'Authentication required.',
      );
    }
  }
}
