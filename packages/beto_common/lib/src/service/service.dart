import 'message.dart';
import 'record.dart';

abstract class BetoService {
  Future<void> submitBenchmarkData(SubmitBenchmarkDataRequest request);

  Future<List<BenchmarkRecord>> queryBenchmarkData(
    QueryBenchmarkDataRequest request,
  );
}
