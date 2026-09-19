import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_error.dart';
import 'package:oncue_mobile/push/application/push_device_session_service.dart';

abstract interface class AuthSessionStore {
  Future<AuthSession?> load();

  Future<void> save(AuthSession session);

  Future<void> clear();
}

final class AuthService {
  AuthService(
    this._authClient,
    this._sessionStore, {
    PushDeviceSessionService? pushDeviceSessionService,
  }) : _pushDeviceSessionService = pushDeviceSessionService;

  final AuthClient _authClient;
  final AuthSessionStore _sessionStore;
  final PushDeviceSessionService? _pushDeviceSessionService;

  Future<void> loginWithKakao({required String providerAccessToken}) async {
    await _login(
      AuthLoginRequest.kakao(providerAccessToken: providerAccessToken),
    );
  }

  Future<void> loginWithX({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    await _login(
      AuthLoginRequest.x(
        authorizationCode: authorizationCode,
        codeVerifier: codeVerifier,
      ),
    );
  }

  Future<void> logout() async {
    final session = await _sessionStore.load();
    try {
      if (session != null) {
        await _detachPushDevice(session.accessToken);
      }
    } finally {
      await _sessionStore.clear();
    }
  }

  Future<AuthSession?> loadSession() async {
    final session = await _sessionStore.load();
    if (session != null) {
      await _attachPushDevice(session.accessToken);
    }
    return session;
  }

  Future<T> runAuthenticated<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiError catch (error) {
      if (error.statusCode == 401) {
        final session = await _sessionStore.load();
        if (session != null) {
          await _detachPushDevice(session.accessToken);
        }
        await _sessionStore.clear();
      }
      rethrow;
    }
  }

  Future<void> _login(AuthLoginRequest request) async {
    final session = await _authClient.login(request);
    await _sessionStore.save(session);
    await _attachPushDevice(session.accessToken);
  }

  Future<void> _attachPushDevice(String accessToken) async {
    try {
      await _pushDeviceSessionService?.attachSession(accessToken);
    } catch (_) {
      // Authentication remains usable when PushKit/APNs registration is unavailable.
    }
  }

  Future<void> _detachPushDevice(String accessToken) async {
    try {
      await _pushDeviceSessionService?.detachSession(accessToken);
    } catch (_) {
      // Local logout/session invalidation must still complete.
    }
  }
}
