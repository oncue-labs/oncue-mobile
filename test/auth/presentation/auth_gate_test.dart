import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/auth/presentation/auth_gate.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';

void main() {
  testWidgets('shows the home after restoring a saved session', (
    WidgetTester tester,
  ) async {
    final session = _session();

    await tester.pumpWidget(
      _testApp(
        authService: _authService(savedSession: session),
        homeBuilder: (restoredSession) => Text(
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
        homeBuilder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OnCue 로그인'), findsOneWidget);
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
        homeBuilder: (session) => Text(
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
}

Widget _testApp({
  required AuthService authService,
  OAuthAuthorizationClient? authorizationClient,
  required Widget Function(AuthSession session) homeBuilder,
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
