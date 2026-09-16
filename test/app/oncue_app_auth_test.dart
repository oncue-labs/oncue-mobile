import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/app/oncue_app.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';

void main() {
  testWidgets(
    'uses the authentication gate when auth dependencies are provided',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        OnCueApp(
          authService: _authService(),
          authorizationClient: _FakeOAuthAuthorizationClient(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OnCue 로그인'), findsOneWidget);
      expect(find.text('통화 조합 선택'), findsNothing);
    },
  );
}

AuthService _authService() {
  return AuthService(
    _FakeAuthApiClient(session: _session()),
    _FakeAuthSessionStore(),
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

  @override
  Future<AuthSession> login(
    String provider,
    String authorizationCode,
    String codeVerifier,
  ) async {
    return session;
  }
}

final class _FakeAuthSessionStore implements AuthSessionStore {
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
  @override
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider) async {
    return const OAuthAuthorizationResult(
      authorizationCode: 'authorization-code',
      codeVerifier: 'code-verifier',
    );
  }
}
