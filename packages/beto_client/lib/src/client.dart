import 'dart:convert';

import 'package:beto_common/beto_common.dart';
import 'package:http/http.dart';

import 'model.dart';

abstract class Credentials {
  const Credentials();

  void _applyToRequest(BaseRequest request);
}

class ApiSecret extends Credentials {
  const ApiSecret(this.apiSecret);

  final String apiSecret;

  @override
  void _applyToRequest(BaseRequest request) {
    request.headers['Authorization'] = 'Bearer secret:$apiSecret';
  }
}

abstract class BetoClient {
  factory BetoClient({
    required Uri serverUrl,
    required Credentials credentials,
  }) =>
      BetoClientImpl(
        serverUrl: serverUrl,
        credentials: credentials,
        client: Client(),
      );

  BetoClient._();

  Future<void> sendBenchmarkResults(Suite suite);

  Future<List<Suite>> queryBenchmarkResults(QueryRequest queryRequest);

  Future<void> close();
}

class BetoClientImpl extends BetoClient {
  BetoClientImpl({
    required Client client,
    required this.serverUrl,
    required Credentials credentials,
  })  : client = _Client(client, credentials),
        super._();

  final Client client;
  final Uri serverUrl;
  final _jsonEncoder = JsonUtf8Encoder();
  final _jsonDecoder = utf8.decoder.fuse(json.decoder);

  @override
  Future<void> sendBenchmarkResults(Suite suite) async {
    await client.post(serverUrl.resolve('/benchmark-results'), body: suite);
  }

  @override
  Future<List<Suite>> queryBenchmarkResults(QueryRequest queryRequest) async {
    final request =
        Request('GET', serverUrl.resolve('/benchmark-results/query'))
          ..bodyBytes = _jsonEncoder.convert(queryRequest);

    final response = await client.send(request);

    final body =
        (await _jsonDecoder.bind(response.stream).first)! as List<Object?>;
    return body.cast<Map<String, dynamic>>().map(Suite.fromJson).toList();
  }

  @override
  Future<void> close() async {
    client.close();
  }
}

class _Client extends BaseClient {
  _Client(this._client, this._credentials);

  final Client _client;
  final Credentials _credentials;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    _credentials._applyToRequest(request);
    final result = await _client.send(request);
    if (result.statusCode == 200) {
      return result;
    }

    final body =
        jsonDecode(await result.stream.bytesToString()) as Map<String, Object?>;
    throw BetoException.fromJson(body);
  }
}
