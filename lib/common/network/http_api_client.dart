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
  Future<JsonHttpResponse> getJson(
    Uri uri, {
    required Map<String, String> headers,
  });

  Future<JsonHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  });

  Future<JsonHttpResponse> patchJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  });

  Future<JsonHttpResponse> putJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  });

  Future<JsonHttpResponse> deleteJson(
    Uri uri, {
    required Map<String, String> headers,
  });
}

final class IoJsonHttpTransport implements JsonHttpTransport {
  IoJsonHttpTransport({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  @override
  Future<JsonHttpResponse> getJson(
    Uri uri, {
    required Map<String, String> headers,
  }) {
    return _send('GET', uri, headers: headers);
  }

  @override
  Future<JsonHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    return _send('POST', uri, headers: headers, body: body);
  }

  @override
  Future<JsonHttpResponse> patchJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    return _send('PATCH', uri, headers: headers, body: body);
  }

  @override
  Future<JsonHttpResponse> putJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    return _send('PUT', uri, headers: headers, body: body);
  }

  @override
  Future<JsonHttpResponse> deleteJson(
    Uri uri, {
    required Map<String, String> headers,
  }) {
    return _send('DELETE', uri, headers: headers);
  }

  Future<JsonHttpResponse> _send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.openUrl(method, uri);
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
  HttpApiClient({required Uri baseUri, JsonHttpTransport? transport})
    : _baseUri = baseUri,
      _transport = transport ?? IoJsonHttpTransport();

  final Uri _baseUri;
  final JsonHttpTransport _transport;

  @override
  Future<Object?> getJson(String requestPath, {String? accessToken}) async {
    final response = await _transport.getJson(
      _baseUri.resolve(requestPath),
      headers: _headers(accessToken),
    );
    return _decodeResponse(response);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    final response = await _transport.postJson(
      _baseUri.resolve(requestPath),
      headers: _headers(accessToken),
      body: requestBody,
    );
    return _decodeObjectResponse(response);
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    final response = await _transport.patchJson(
      _baseUri.resolve(requestPath),
      headers: _headers(accessToken),
      body: requestBody,
    );
    return _decodeObjectResponse(response);
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    final response = await _transport.putJson(
      _baseUri.resolve(requestPath),
      headers: _headers(accessToken),
      body: requestBody,
    );
    return _decodeObjectResponse(response);
  }

  @override
  Future<Object?> deleteJson(String requestPath, {String? accessToken}) async {
    final response = await _transport.deleteJson(
      _baseUri.resolve(requestPath),
      headers: _headers(accessToken),
    );
    return _decodeResponse(response);
  }

  Map<String, String> _headers(String? accessToken) {
    final headers = <String, String>{'content-type': 'application/json'};
    if (accessToken != null) {
      headers['authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Object? _decodeResponse(JsonHttpResponse response) {
    final responseBody = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError.fromJson(
        response.statusCode,
        responseBody is Map
            ? Map<String, dynamic>.from(responseBody)
            : <String, dynamic>{},
      );
    }
    return responseBody;
  }

  Map<String, dynamic> _decodeObjectResponse(JsonHttpResponse response) {
    final responseBody = _decodeResponse(response);
    if (responseBody is! Map) {
      throw const FormatException('API response must be a JSON object');
    }
    return Map<String, dynamic>.from(responseBody);
  }

  Object? _decodeJson(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(responseBody);
  }
}
