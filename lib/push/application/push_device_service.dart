import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oncue_mobile/push/application/push_device_session_service.dart';
import 'package:oncue_mobile/push/data/push_device_api_client.dart';
import 'package:oncue_mobile/push/data/push_device_token_source.dart';
import 'package:oncue_mobile/push/model/push_environment.dart';

final class PushDeviceService implements PushDeviceSessionService {
  PushDeviceService(
    this._apiClient,
    this._tokenSource, {
    required this.environment,
  }) {
    _tokenSubscription = _tokenSource.tokenUpdates.listen(_handleTokenUpdate);
  }

  final PushDeviceApiClientContract _apiClient;
  final PushDeviceTokenSource _tokenSource;
  final PushEnvironment environment;
  late final StreamSubscription<String> _tokenSubscription;
  String? _accessToken;

  @override
  Future<void> attachSession(String accessToken) async {
    _accessToken = accessToken;
    final deviceToken = await _tokenSource.currentDeviceToken();
    _debugLog(
      'session attached: tokenAvailable=${deviceToken != null && deviceToken.trim().isNotEmpty}, '
      'environment=${environment.wireValue}',
    );
    if (deviceToken == null || deviceToken.trim().isEmpty) {
      _debugLog('registration skipped because no VoIP token is available');
      return;
    }
    try {
      await _apiClient.register(
        deviceToken: deviceToken,
        environment: environment,
        accessToken: accessToken,
      );
      _debugLog('device registration succeeded');
    } catch (error) {
      _debugLog('device registration failed: ${error.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<void> detachSession(String accessToken) async {
    _accessToken = null;
    await _apiClient.delete(accessToken: accessToken);
  }

  Future<void> _handleTokenUpdate(String deviceToken) async {
    final accessToken = _accessToken;
    _debugLog('VoIP token update received: sessionAttached=${accessToken != null}');
    if (accessToken == null || deviceToken.trim().isEmpty) {
      return;
    }
    try {
      await _apiClient.register(
        deviceToken: deviceToken,
        environment: environment,
        accessToken: accessToken,
      );
      _debugLog('device registration after token update succeeded');
    } catch (error) {
      _debugLog(
        'device registration after token update failed: ${error.runtimeType}',
      );
      // A later token event or session restore retries registration.
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[PushDevice] $message');
    }
  }

  Future<void> dispose() => _tokenSubscription.cancel();
}
