import 'dart:async';

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

abstract interface class AuthSessionProvider {
  AuthSession? get currentSession;

  /// Returns the current session, loading it from storage first if it has
  /// not been restored into memory yet. A VoIP push can launch the app in
  /// the background and reach call handling before the UI's own session
  /// restore completes, so callers that need the session outside the normal
  /// UI startup path must await this instead of reading [currentSession].
  Future<AuthSession?> ensureSessionLoaded();
}

final class AuthService implements AuthSessionProvider {
  AuthService(
    this._authClient,
    this._sessionStore, {
    PushDeviceSessionService? pushDeviceSessionService,
  }) : _pushDeviceSessionService = pushDeviceSessionService;

  final AuthClient _authClient;
  final AuthSessionStore _sessionStore;
  final PushDeviceSessionService? _pushDeviceSessionService;
  AuthSession? _currentSession;
  final _sessionChanges = StreamController<AuthSession?>.broadcast();
  Future<String?>? _refreshInFlight;

  Stream<AuthSession?> get sessionChanges => _sessionChanges.stream;

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  Future<AuthSession?> ensureSessionLoaded() async {
    if (_currentSession != null) {
      return _currentSession;
    }
    return loadSession();
  }

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
    final session = _currentSession ?? await _sessionStore.load();
    try {
      if (session != null) {
        if (session.refreshToken != null) {
          try {
            await _authClient.revoke(session.refreshToken!);
          } catch (_) {
            // Local logout must still complete when the server is unavailable.
          }
        }
        await _detachPushDevice(session.accessToken);
      }
    } finally {
      await _sessionStore.clear();
      _setCurrentSession(null);
    }
  }

  Future<AuthSession?> loadSession() async {
    final session = await _sessionStore.load();
    if (session != null) {
      await _attachPushDevice(session.accessToken);
    }
    _setCurrentSession(session);
    return session;
  }

  Future<String?> refreshAccessToken(String failedAccessToken) async {
    final session = _currentSession ?? await _sessionStore.load();
    if (session == null || session.accessToken != failedAccessToken) {
      return _currentSession?.accessToken;
    }
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _invalidateSession();
      return null;
    }
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final refreshFuture = _refreshSession(refreshToken);
    _refreshInFlight = refreshFuture;
    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    }
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
        _setCurrentSession(null);
      }
      rethrow;
    }
  }

  Future<void> _login(AuthLoginRequest request) async {
    final session = await _authClient.login(request);
    await _sessionStore.save(session);
    _setCurrentSession(session);
    await _attachPushDevice(session.accessToken);
  }

  Future<String?> _refreshSession(String refreshToken) async {
    try {
      final session = await _authClient.refresh(refreshToken);
      await _sessionStore.save(session);
      _setCurrentSession(session);
      return session.accessToken;
    } on ApiError catch (error) {
      if (error.statusCode == 400 ||
          error.statusCode == 401 ||
          error.statusCode == 403) {
        await _invalidateSession();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _invalidateSession() async {
    await _sessionStore.clear();
    _setCurrentSession(null);
  }

  void _setCurrentSession(AuthSession? session) {
    _currentSession = session;
    if (!_sessionChanges.isClosed) {
      _sessionChanges.add(session);
    }
  }

  Future<void> dispose() async {
    await _sessionChanges.close();
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
