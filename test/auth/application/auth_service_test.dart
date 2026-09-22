import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_error.dart';
import 'package:oncue_mobile/push/application/push_device_session_service.dart';

void main() {
  test('saves a Kakao login session after a successful login', () async {
    final authApiClient = _FakeAuthApiClient(session: _session());
    final sessionStore = _FakeAuthSessionStore();
    final pushService = _FakePushDeviceSessionService();
    final service = AuthService(
      authApiClient,
      sessionStore,
      pushDeviceSessionService: pushService,
    );

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
    expect(pushService.attachedAccessTokens, ['access-token']);
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

  test(
    'refreshes and persists a session after an expired access token',
    () async {
      final sessionStore = _FakeAuthSessionStore(savedSession: _session());
      final refreshedSession = _session(
        accessToken: 'refreshed-access-token',
        createdAt: DateTime.parse('2026-09-15T10:02:00Z'),
        expiresAt: DateTime.parse('2026-09-15T11:02:00Z'),
      );
      final authApiClient = _FakeAuthApiClient(
        session: _session(),
        refreshedSession: refreshedSession,
      );
      final service = AuthService(authApiClient, sessionStore);
      await service.loadSession();

      final accessToken = await service.refreshAccessToken('access-token');

      expect(accessToken, 'refreshed-access-token');
      expect(sessionStore.savedSession, same(refreshedSession));
      expect(service.currentSession, same(refreshedSession));
      expect(authApiClient.refreshedTokens, ['refresh-token']);
    },
  );

  test('clears the session when the refresh token is rejected', () async {
    final sessionStore = _FakeAuthSessionStore(savedSession: _session());
    final authApiClient = _FakeAuthApiClient(
      session: _session(),
      refreshError: const ApiError(statusCode: 401, message: 'expired'),
    );
    final service = AuthService(authApiClient, sessionStore);
    await service.loadSession();

    expect(await service.refreshAccessToken('access-token'), isNull);
    expect(sessionStore.clearCount, 1);
    expect(service.currentSession, isNull);
  });

  test('clears the saved session explicitly on logout', () async {
    final sessionStore = _FakeAuthSessionStore(savedSession: _session());
    final pushService = _FakePushDeviceSessionService();
    final service = AuthService(
      _FakeAuthApiClient(session: _session()),
      sessionStore,
      pushDeviceSessionService: pushService,
    );

    await service.logout();

    expect(pushService.detachedAccessTokens, ['access-token']);
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

AuthSession _session({
  String accessToken = 'access-token',
  DateTime? expiresAt,
  DateTime? createdAt,
}) {
  return AuthSession(
    accessToken: accessToken,
    expiresAt: expiresAt ?? DateTime.parse('2026-09-15T10:01:00Z'),
    createdAt: createdAt ?? DateTime.parse('2026-09-15T10:00:00Z'),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.parse('2026-10-15T10:00:00Z'),
  );
}

final class _FakeAuthApiClient implements AuthClient {
  _FakeAuthApiClient({
    required this.session,
    this.refreshedSession,
    this.refreshError,
  });

  final AuthSession session;
  final AuthSession? refreshedSession;
  final ApiError? refreshError;
  String? provider;
  String? providerAccessToken;
  String? authorizationCode;
  String? codeVerifier;
  final refreshedTokens = <String>[];

  @override
  Future<AuthSession> login(AuthLoginRequest request) async {
    provider = request.provider;
    providerAccessToken = request.providerAccessToken;
    authorizationCode = request.authorizationCode;
    codeVerifier = request.codeVerifier;
    return session;
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshedTokens.add(refreshToken);
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshedSession ?? session;
  }

  @override
  Future<void> revoke(String refreshToken) async {}
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

final class _FakePushDeviceSessionService implements PushDeviceSessionService {
  final attachedAccessTokens = <String>[];
  final detachedAccessTokens = <String>[];

  @override
  Future<void> attachSession(String accessToken) async {
    attachedAccessTokens.add(accessToken);
  }

  @override
  Future<void> detachSession(String accessToken) async {
    detachedAccessTokens.add(accessToken);
  }
}
