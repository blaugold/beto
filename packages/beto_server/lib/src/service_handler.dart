// ignore_for_file: avoid_types_on_closure_parameters

import 'package:beto_common/beto_common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'middleware.dart';

Handler betoServiceHandler(BetoService service) {
  final router = Router()
    ..post('/benchmark-data', (Request request) async {
      final requestObject =
          request.deserializeJson(SubmitBenchmarkDataRequest.fromJson);
      await service.submitBenchmarkData(requestObject);
      return Response.ok(null);
    })
    ..get('/benchmark-data/query', (Request request) async {
      final requestObject =
          request.deserializeJson(QueryBenchmarkDataRequest.fromJson);
      final responseObject = await service.queryBenchmarkData(requestObject);
      return responseObject.jsonResponse();
    });

  return const Pipeline().addMiddleware(betoErrorHandling()).addHandler(router);
}
