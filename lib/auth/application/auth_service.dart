import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_error.dart';

abstract interface class AuthSessionStore {
  Future<AuthSession?> load();

  Future<void> save(AuthSession session);

  Future<void> clear();
}

final class AuthService {
  AuthService(this._authClient, this._sessionStore);

  final AuthClient _authClient;
  final AuthSessionStore _sessionStore;

  Future<void> loginWithKakao({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    await _login(
      provider: 'kakao',
      authorizationCode: authorizationCode,
      codeVerifier: codeVerifier,
    );
  }

  Future<void> loginWithX({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    await _login(
      provider: 'x',
      authorizationCode: authorizationCode,
      codeVerifier: codeVerifier,
    );
  }

  Future<void> logout() => _sessionStore.clear();

  Future<AuthSession?> loadSession() => _sessionStore.load();

  Future<T> runAuthenticated<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiError catch (error) {
      if (error.statusCode == 401) {
        await _sessionStore.clear();
      }
      rethrow;
    }
  }

  Future<void> _login({
    required String provider,
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    final session = await _authClient.login(
      provider,
      authorizationCode,
      codeVerifier,
    );
    await _sessionStore.save(session);
  }
}
