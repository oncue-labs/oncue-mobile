import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_error.dart';

void main() {
  test('saves a Kakao login session after a successful login', () async {
    final authApiClient = _FakeAuthApiClient(session: _session());
    final sessionStore = _FakeAuthSessionStore();
    final service = AuthService(authApiClient, sessionStore);

    await service.loginWithKakao(
      providerAccessToken: 'kakao-provider-access-token',
    );

    expect(authApiClient.provider, 'kakao');
    expect(authApiClient.providerAccessToken, 'kakao-provider-access-token');
    expect(sessionStore.savedSession?.accessToken, 'access-token');
    expect(
      sessionStore.savedSession?.expiresAt,
      DateTime.parse('2026-09-15T10:01:00Z'),
    );
  });

  test(
    'saves an X login session after sending authorization code and verifier',
    () async {
      final authApiClient = _FakeAuthApiClient(session: _session());
      final sessionStore = _FakeAuthSessionStore();
      final service = AuthService(authApiClient, sessionStore);

      await service.loginWithX(
        authorizationCode: 'x-authorization-code',
        codeVerifier: 'x-code-verifier',
      );

      expect(authApiClient.provider, 'x');
      expect(authApiClient.authorizationCode, 'x-authorization-code');
      expect(authApiClient.codeVerifier, 'x-code-verifier');
    },
  );

  test(
    'clears the saved session when an authenticated request returns 401',
    () async {
      final sessionStore = _FakeAuthSessionStore(savedSession: _session());
      final service = AuthService(
        _FakeAuthApiClient(session: _session()),
        sessionStore,
      );

      await expectLater(
        service.runAuthenticated(() async {
          throw const ApiError(statusCode: 401, message: 'Unauthorized');
        }),
        throwsA(isA<ApiError>()),
      );

      expect(sessionStore.clearCount, 1);
    },
  );

  test('clears the saved session explicitly on logout', () async {
    final sessionStore = _FakeAuthSessionStore(savedSession: _session());
    final service = AuthService(
      _FakeAuthApiClient(session: _session()),
      sessionStore,
    );

    await service.logout();

    expect(sessionStore.clearCount, 1);
  });

  test('loads the saved session when the app starts', () async {
    final savedSession = _session();
    final sessionStore = _FakeAuthSessionStore(savedSession: savedSession);
    final service = AuthService(
      _FakeAuthApiClient(session: savedSession),
      sessionStore,
    );

    final session = await service.loadSession();

    expect(session, same(savedSession));
  });
}

AuthSession _session() {
  return AuthSession(
    accessToken: 'access-token',
    expiresAt: DateTime.parse('2026-09-15T10:01:00Z'),
    createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
  );
}

final class _FakeAuthApiClient implements AuthClient {
  _FakeAuthApiClient({required this.session});

  final AuthSession session;
  String? provider;
  String? providerAccessToken;
  String? authorizationCode;
  String? codeVerifier;

  @override
  Future<AuthSession> login(AuthLoginRequest request) async {
    provider = request.provider;
    providerAccessToken = request.providerAccessToken;
    authorizationCode = request.authorizationCode;
    codeVerifier = request.codeVerifier;
    return session;
  }
}

final class _FakeAuthSessionStore implements AuthSessionStore {
  _FakeAuthSessionStore({this.savedSession});

  AuthSession? savedSession;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
    savedSession = null;
  }

  @override
  Future<AuthSession?> load() async => savedSession;

  @override
  Future<void> save(AuthSession session) async {
    savedSession = session;
  }
}
