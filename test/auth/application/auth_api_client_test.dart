import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

void main() {
  test('logs in with the confirmed request and response contract', () async {
    final apiClient = _RecordingApiClient(
      response: {
        'accessToken': 'access-token',
        'expiresAt': '2026-09-12T10:01:00Z',
        'createdAt': '2026-09-12T10:00:00Z',
      },
    );
    final client = AuthApiClient(apiClient);

    final session = await client.login(
      const AuthLoginRequest.kakao(
        providerAccessToken: 'kakao-provider-access-token',
      ),
    );

    expect(apiClient.path, '/api/v1/auth/login');
    expect(apiClient.body, {
      'provider': 'kakao',
      'providerAccessToken': 'kakao-provider-access-token',
    });
    expect(session, isA<AuthSession>());
    expect(session.accessToken, 'access-token');
    expect(session.expiresAt, DateTime.parse('2026-09-12T10:01:00Z'));
    expect(session.createdAt, DateTime.parse('2026-09-12T10:00:00Z'));
  });

  test('sends X authorization code and PKCE verifier', () async {
    final apiClient = _RecordingApiClient(
      response: {
        'accessToken': 'access-token',
        'expiresAt': '2026-09-12T10:01:00Z',
        'createdAt': '2026-09-12T10:00:00Z',
      },
    );
    final client = AuthApiClient(apiClient);

    await client.login(
      const AuthLoginRequest.x(
        authorizationCode: 'x-authorization-code',
        codeVerifier: 'x-code-verifier',
      ),
    );

    expect(apiClient.body, {
      'provider': 'x',
      'authorizationCode': 'x-authorization-code',
      'codeVerifier': 'x-code-verifier',
    });
  });
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<Object?> getJson(String requestPath, {String? accessToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    path = requestPath;
    body = requestBody;
    return response;
  }
}
