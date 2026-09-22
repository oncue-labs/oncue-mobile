import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/auth/presentation/auth_gate.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_error.dart';

void main() {
  testWidgets('shows the home after restoring a saved session', (
    WidgetTester tester,
  ) async {
    final session = _session();

    await tester.pumpWidget(
      _testApp(
        authService: _authService(savedSession: session),
        homeBuilder: (restoredSession, _) => Text(
          'home:${restoredSession.accessToken}',
          key: const ValueKey('authenticated-home'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('authenticated-home')), findsOneWidget);
    expect(find.text('home:access-token'), findsOneWidget);
    expect(find.byType(AuthGate), findsOneWidget);
  });

  testWidgets('shows login when there is no saved session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        authService: _authService(),
        homeBuilder: (_, _) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('원하는 순간에 걸려올 전화를 만들어보세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-kakao-button')), findsOneWidget);
  });

  testWidgets('logs in with the selected provider and opens the home', (
    WidgetTester tester,
  ) async {
    final authApiClient = _FakeAuthApiClient(session: _session());
    final authService = AuthService(authApiClient, _FakeAuthSessionStore());
    final authorizationClient = _FakeOAuthAuthorizationClient();

    await tester.pumpWidget(
      _testApp(
        authService: authService,
        authorizationClient: authorizationClient,
        homeBuilder: (session, _) => Text(
          'home:${session.accessToken}',
          key: const ValueKey('authenticated-home'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-kakao-button')));
    await tester.pumpAndSettle();

    expect(authorizationClient.provider, AuthProvider.kakao);
    expect(authApiClient.provider, 'kakao');
    expect(authApiClient.providerAccessToken, 'kakao-provider-access-token');
    expect(find.byKey(const ValueKey('authenticated-home')), findsOneWidget);
  });

  testWidgets('logs out and returns to the login screen', (
    WidgetTester tester,
  ) async {
    final store = _FakeAuthSessionStore(savedSession: _session());
    final authService = AuthService(
      _FakeAuthApiClient(session: _session()),
      store,
    );

    await tester.pumpWidget(
      _testApp(
        authService: authService,
        homeBuilder: (session, onLogout) => TextButton(
          key: const ValueKey('logout-test-button'),
          onPressed: () => onLogout(),
          child: Text(session.accessToken),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('logout-test-button')));
    await tester.pumpAndSettle();

    expect(store.savedSession, isNull);
    expect(find.text('원하는 순간에 걸려올 전화를 만들어보세요.'), findsOneWidget);
  });

  testWidgets('returns to login when an expired refresh token is rejected', (
    WidgetTester tester,
  ) async {
    final authApiClient = _FakeAuthApiClient(
      session: _session(),
      refreshError: const ApiError(statusCode: 401, message: 'expired'),
    );
    final authService = AuthService(
      authApiClient,
      _FakeAuthSessionStore(savedSession: _session()),
    );

    await tester.pumpWidget(
      _testApp(
        authService: authService,
        homeBuilder: (session, _) => const Text('authenticated-home'),
      ),
    );
    await tester.pumpAndSettle();

    await authService.refreshAccessToken('access-token');
    await tester.pumpAndSettle();

    expect(find.text('원하는 순간에 걸려올 전화를 만들어보세요.'), findsOneWidget);
  });
}

Widget _testApp({
  required AuthService authService,
  OAuthAuthorizationClient? authorizationClient,
  required Widget Function(
    AuthSession session,
    Future<void> Function() onLogout,
  )
  homeBuilder,
}) {
  return MaterialApp(
    home: AuthGate(
      authService: authService,
      authorizationClient:
          authorizationClient ?? _FakeOAuthAuthorizationClient(),
      homeBuilder: homeBuilder,
    ),
  );
}

AuthService _authService({AuthSession? savedSession}) {
  return AuthService(
    _FakeAuthApiClient(session: _session()),
    _FakeAuthSessionStore(savedSession: savedSession),
  );
}

AuthSession _session() {
  return AuthSession(
    accessToken: 'access-token',
    expiresAt: DateTime.parse('2026-09-15T10:01:00Z'),
    createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.parse('2026-10-15T10:00:00Z'),
  );
}

final class _FakeAuthApiClient implements AuthClient {
  _FakeAuthApiClient({required this.session, this.refreshError});

  final AuthSession session;
  final ApiError? refreshError;
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

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return session;
  }

  @override
  Future<void> revoke(String refreshToken) async {}
}

final class _FakeAuthSessionStore implements AuthSessionStore {
  _FakeAuthSessionStore({this.savedSession});

  AuthSession? savedSession;

  @override
  Future<void> clear() async {
    savedSession = null;
  }

  @override
  Future<AuthSession?> load() async => savedSession;

  @override
  Future<void> save(AuthSession session) async {
    savedSession = session;
  }
}

final class _FakeOAuthAuthorizationClient implements OAuthAuthorizationClient {
  AuthProvider? provider;

  @override
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider) async {
    this.provider = provider;
    return const OAuthAuthorizationResult.kakao(
      providerAccessToken: 'kakao-provider-access-token',
    );
  }
}
