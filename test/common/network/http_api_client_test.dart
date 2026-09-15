import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/network/api_error.dart';
import 'package:oncue_mobile/common/network/http_api_client.dart';

void main() {
  test('posts JSON with a bearer token and decodes a successful response', () async {
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

    expect(transport.uri, Uri.parse('https://api.oncue.test/api/v1/auth/login'));
    expect(transport.headers, {
      'content-type': 'application/json',
      'authorization': 'Bearer access-token',
    });
    expect(transport.body, {'provider': 'kakao'});
    expect(response, {'accessToken': 'access-token'});
  });

  test('converts a non-success response into the common API error', () async {
    final client = HttpApiClient(
      baseUri: Uri.parse('https://api.oncue.test/'),
      transport: _RecordingJsonHttpTransport(
        response: const JsonHttpResponse(
          statusCode: 409,
          body: '{"code":"RESERVATION_CONFLICT","message":"겹치는 예약입니다.","requestId":"request-1"}',
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
}

final class _RecordingJsonHttpTransport implements JsonHttpTransport {
  _RecordingJsonHttpTransport({required this.response});

  final JsonHttpResponse response;
  Uri? uri;
  Map<String, String>? headers;
  Map<String, dynamic>? body;

  @override
  Future<JsonHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    this.uri = uri;
    this.headers = headers;
    this.body = body;
    return response;
  }
}
