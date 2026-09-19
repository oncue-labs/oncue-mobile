import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/network/api_error.dart';
import 'package:oncue_mobile/common/network/http_api_client.dart';

void main() {
  test('encodes non-Latin JSON request bodies as UTF-8', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestBody = Completer<String>();
    final serverSubscription = server.listen((request) async {
      requestBody.complete(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"ok":true}');
      await request.response.close();
    });

    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final response = await IoJsonHttpTransport().postJson(
      Uri.parse('http://${server.address.host}:${server.port}/reservations'),
      headers: const {'content-type': 'application/json'},
      body: const {'scenarioContext': '아이가 빨리 잠들 수 있게 해 주세요'},
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(jsonDecode(await requestBody.future), {
      'scenarioContext': '아이가 빨리 잠들 수 있게 해 주세요',
    });
  });

  test(
    'posts JSON with a bearer token and decodes a successful response',
    () async {
      final transport = _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(
          statusCode: 200,
          body: '{"accessToken":"access-token"}',
        ),
      );
      final client = HttpApiClient(
        baseUri: Uri.parse('https://api.oncue.test/'),
        transport: transport,
      );

      final response = await client.postJson(
        '/api/v1/auth/login',
        requestBody: {'provider': 'kakao'},
        accessToken: 'access-token',
      );

      expect(
        transport.uri,
        Uri.parse('https://api.oncue.test/api/v1/auth/login'),
      );
      expect(transport.headers, {
        'content-type': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(transport.body, {'provider': 'kakao'});
      expect(response, {'accessToken': 'access-token'});
    },
  );

  test('converts a non-success response into the common API error', () async {
    final client = HttpApiClient(
      baseUri: Uri.parse('https://api.oncue.test/'),
      transport: _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(
          statusCode: 409,
          body:
              '{"code":"RESERVATION_CONFLICT","message":"겹치는 예약입니다.","requestId":"request-1"}',
        ),
      ),
    );

    await expectLater(
      client.postJson('/api/v1/reservations'),
      throwsA(
        isA<ApiError>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having((error) => error.code, 'code', 'RESERVATION_CONFLICT')
            .having((error) => error.requestId, 'requestId', 'request-1'),
      ),
    );
  });

  test(
    'supports GET and PATCH JSON requests through the same transport',
    () async {
      final getTransport = _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(statusCode: 200, body: '[{"id":1}]'),
      );
      final getClient = HttpApiClient(
        baseUri: Uri.parse('https://api.oncue.test/'),
        transport: getTransport,
      );

      final listResponse = await getClient.getJson('/api/v1/reservations');

      expect(getTransport.method, 'GET');
      expect(listResponse, [
        {'id': 1},
      ]);

      final patchTransport = _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(
          statusCode: 200,
          body: '{"reservationStatus":"SCHEDULED"}',
        ),
      );
      final patchClient = HttpApiClient(
        baseUri: Uri.parse('https://api.oncue.test/'),
        transport: patchTransport,
      );

      final patchResponse = await patchClient.patchJson(
        '/api/v1/reservations/1001',
        requestBody: {'callGoal': '목표'},
      );

      expect(patchTransport.method, 'PATCH');
      expect(patchTransport.body, {'callGoal': '목표'});
      expect(patchResponse, {'reservationStatus': 'SCHEDULED'});
    },
  );

  test(
    'supports PUT and DELETE JSON requests through the same transport',
    () async {
      final putTransport = _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(statusCode: 200, body: '{}'),
      );
      final putClient = HttpApiClient(
        baseUri: Uri.parse('https://api.oncue.test/'),
        transport: putTransport,
      );

      await putClient.putJson(
        '/api/v1/push-device',
        requestBody: {'deviceToken': 'token'},
        accessToken: 'access-token',
      );

      expect(putTransport.method, 'PUT');
      expect(putTransport.body, {'deviceToken': 'token'});
      expect(putTransport.headers?['authorization'], 'Bearer access-token');

      final deleteTransport = _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(statusCode: 204, body: ''),
      );
      final deleteClient = HttpApiClient(
        baseUri: Uri.parse('https://api.oncue.test/'),
        transport: deleteTransport,
      );

      await deleteClient.deleteJson(
        '/api/v1/push-device',
        accessToken: 'access-token',
      );

      expect(deleteTransport.method, 'DELETE');
      expect(deleteTransport.body, isNull);
      expect(deleteTransport.headers?['authorization'], 'Bearer access-token');
    },
  );
}

final class _RecordingJsonHttpTransport implements JsonHttpTransport {
  _RecordingJsonHttpTransport({required this.response});

  final JsonHttpResponse response;
  String? method;
  Uri? uri;
  Map<String, String>? headers;
  Map<String, dynamic>? body;

  @override
  Future<JsonHttpResponse> getJson(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    method = 'GET';
    this.uri = uri;
    this.headers = headers;
    return response;
  }

  @override
  Future<JsonHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    method = 'POST';
    this.uri = uri;
    this.headers = headers;
    this.body = body;
    return response;
  }

  @override
  Future<JsonHttpResponse> patchJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    method = 'PATCH';
    this.uri = uri;
    this.headers = headers;
    this.body = body;
    return response;
  }

  @override
  Future<JsonHttpResponse> putJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    method = 'PUT';
    this.uri = uri;
    this.headers = headers;
    this.body = body;
    return response;
  }

  @override
  Future<JsonHttpResponse> deleteJson(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    method = 'DELETE';
    this.uri = uri;
    this.headers = headers;
    body = null;
    return response;
  }
}
