import 'message.dart';
import 'value.dart';

abstract class BetoService {
  Future<void> submitBenchmarkData(SubmitBenchmarkDataRequest request);

  Future<List<Suite>> queryBenchmarkData(QueryBenchmarkDataRequest request);
}
