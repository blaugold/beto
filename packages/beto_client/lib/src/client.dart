import 'dart:convert';
import 'dart:io';

import 'package:beto_common/beto_common.dart';
import 'package:http/http.dart';

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

class BetoServiceHttpClient extends BetoService {
  BetoServiceHttpClient({
    Client? client,
    required this.serverUrl,
    required Credentials credentials,
  }) : client = _Client(client ?? Client(), credentials);

  final Client client;
  final Uri serverUrl;
  final _jsonEncoder = JsonUtf8Encoder();
  final _jsonDecoder = utf8.decoder.fuse(json.decoder);

  Future<void> close() async {
    client.close();
  }

  @override
  Future<void> submitBenchmarkData(SubmitBenchmarkDataRequest request) async {
    await client.post(
      serverUrl.resolve('/benchmark-data'),
      body: _jsonEncoder.convert(request),
      headers: {
        HttpHeaders.contentTypeHeader: ContentType.json.toString(),
      },
    );
  }

  @override
  Future<List<BenchmarkRecord>> queryBenchmarkData(
    QueryBenchmarkDataRequest request,
  ) async {
    final httpRequest =
        Request('GET', serverUrl.resolve('/benchmark-data/query'))
          ..bodyBytes = _jsonEncoder.convert(request)
          ..headers.addAll({
            HttpHeaders.contentTypeHeader: ContentType.json.toString(),
          });

    final response = await client.send(httpRequest);

    final body =
        (await _jsonDecoder.bind(response.stream).first)! as List<Object?>;
    return body
        .cast<Map<String, Object?>>()
        .map(BenchmarkRecord.fromJson)
        .toList();
  }
}

class _Client extends BaseClient {
  _Client(this._client, this._credentials);

  final Client _client;
  final Credentials _credentials;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    _credentials._applyToRequest(request);
    final response = await _client.send(request);
    if (response.statusCode == 200) {
      return response;
    }

    final textBody = await response.stream.bytesToString();

    final Exception exception;
    try {
      final jsonBody = jsonDecode(textBody) as Map<String, Object?>;
      exception = BetoException.fromJson(jsonBody);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      throw BetoException(
        statusCode: response.statusCode,
        message: textBody,
      );
    }
    throw exception;
  }
}
