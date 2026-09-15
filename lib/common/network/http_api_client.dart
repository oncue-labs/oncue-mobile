import 'dart:convert';
import 'dart:io';

import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/common/network/api_error.dart';

final class JsonHttpResponse {
  const JsonHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

abstract interface class JsonHttpTransport {
  Future<JsonHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  });
}

final class IoJsonHttpTransport implements JsonHttpTransport {
  IoJsonHttpTransport({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  @override
  Future<JsonHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.postUrl(uri);
    headers.forEach(request.headers.set);
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    return JsonHttpResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }
}

final class HttpApiClient implements ApiClient {
  HttpApiClient({
    required Uri baseUri,
    JsonHttpTransport? transport,
  }) : _baseUri = baseUri,
       _transport = transport ?? IoJsonHttpTransport();

  final Uri _baseUri;
  final JsonHttpTransport _transport;

  @override
  Future<Map<String, dynamic>> postJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'content-type': 'application/json',
    };
    if (accessToken != null) {
      headers['authorization'] = 'Bearer $accessToken';
    }

    final response = await _transport.postJson(
      _baseUri.resolve(requestPath),
      headers: headers,
      body: requestBody,
    );
    final responseBody = _decodeObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError.fromJson(response.statusCode, responseBody);
    }
    return responseBody;
  }

  Map<String, dynamic> _decodeObject(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decodedBody = jsonDecode(responseBody);
    if (decodedBody is! Map) {
      throw const FormatException('API response must be a JSON object');
    }
    return Map<String, dynamic>.from(decodedBody);
  }
}
