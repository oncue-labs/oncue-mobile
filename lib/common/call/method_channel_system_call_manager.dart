import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oncue_mobile/common/call/system_call_manager.dart';

final class MethodChannelSystemCallManager implements SystemCallManager {
  MethodChannelSystemCallManager({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const channelName = 'oncue/system_calls';

  static const _presentIncomingCallMethod = 'presentIncomingCall';
  static const _endCallMethod = 'endCall';
  static const _answerSucceededMethod = 'answerSucceeded';
  static const _answerFailedMethod = 'answerFailed';
  static const _answeredEvent = 'onAnswered';
  static const _rejectedEvent = 'onRejected';
  static const _endedEvent = 'onEnded';

  final MethodChannel _channel;
  final StreamController<String> _answered =
      StreamController<String>.broadcast();
  final StreamController<String> _rejected =
      StreamController<String>.broadcast();
  final StreamController<String> _ended = StreamController<String>.broadcast();

  @override
  Stream<String> get onAnswered => _answered.stream;

  @override
  Stream<String> get onRejected => _rejected.stream;

  @override
  Stream<String> get onEnded => _ended.stream;

  @override
  Future<void> presentIncomingCall(IncomingCallDisplayInfo call) {
    return _channel.invokeMethod<void>(_presentIncomingCallMethod, {
      'callSessionId': call.callSessionId,
      'displayName': call.displayName,
      'callType': call.callType,
    });
  }

  @override
  Future<void> endCall(String callSessionId) {
    return _invokeCallCommand(_endCallMethod, callSessionId);
  }

  @override
  Future<void> answerSucceeded(String callSessionId) {
    return _invokeCallCommand(_answerSucceededMethod, callSessionId);
  }

  @override
  Future<void> answerFailed(String callSessionId) {
    return _invokeCallCommand(_answerFailedMethod, callSessionId);
  }

  Future<void> _invokeCallCommand(String method, String callSessionId) {
    return _channel.invokeMethod<void>(method, {
      'callSessionId': callSessionId,
    });
  }

  Future<Object?> _handleNativeCall(MethodCall call) async {
    final callSessionId = _callSessionIdFrom(call.arguments);
    if (callSessionId == null) {
      throw PlatformException(
        code: 'INVALID_CALL_SESSION_ID',
        message:
            'The native call event must contain a non-empty callSessionId.',
      );
    }

    switch (call.method) {
      case _answeredEvent:
        _answered.add(callSessionId);
      case _rejectedEvent:
        _rejected.add(callSessionId);
      case _endedEvent:
        _ended.add(callSessionId);
      default:
        throw MissingPluginException(
          'Unknown system call event: ${call.method}',
        );
    }
    return null;
  }

  String? _callSessionIdFrom(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await Future.wait([_answered.close(), _rejected.close(), _ended.close()]);
  }
}
