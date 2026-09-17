import 'package:oncue_mobile/common/call/system_call_manager.dart';

final class IncomingCallService {
  IncomingCallService(this._systemCallManager);

  final SystemCallManager _systemCallManager;
  final Set<String> _reportedCallSessionIds = <String>{};

  Stream<String> get onAnswered => _systemCallManager.onAnswered;

  Stream<String> get onRejected => _systemCallManager.onRejected;

  Stream<String> get onEnded => _systemCallManager.onEnded;

  Future<void> handleVoipPayload(Map<String, dynamic> payload) async {
    final callSessionId = _callSessionIdFrom(payload['callSessionId']);
    final displayName = _displayNameFrom(payload['displayName']);
    if (callSessionId == null || displayName == null) {
      return;
    }
    if (_reportedCallSessionIds.contains(callSessionId)) {
      return;
    }

    final call = IncomingCallDisplayInfo(
      callSessionId: callSessionId,
      displayName: displayName,
      callType: _callTypeFrom(payload['callType']),
    );

    try {
      await _systemCallManager.presentIncomingCall(call);
      _reportedCallSessionIds.add(callSessionId);
    } catch (error, stackTrace) {
      throw SystemCallRegistrationException(
        callSessionId: callSessionId,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _callSessionIdFrom(Object? value) {
    if (value is String) {
      final normalizedValue = value.trim();
      return normalizedValue.isEmpty ? null : normalizedValue;
    }
    if (value is int) {
      return value.toString();
    }
    return null;
  }

  String? _displayNameFrom(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  String _callTypeFrom(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return 'voice';
  }
}

final class SystemCallRegistrationException implements Exception {
  const SystemCallRegistrationException({
    required this.callSessionId,
    required this.cause,
    required this.stackTrace,
  });

  final String callSessionId;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'System call registration failed for $callSessionId: $cause';
  }
}
