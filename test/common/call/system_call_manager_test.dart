import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/call/system_call_manager.dart';

void main() {
  test('registers an incoming call with its display contract', () async {
    final manager = _RecordingSystemCallManager();
    addTearDown(manager.dispose);
    final call = IncomingCallDisplayInfo(
      callSessionId: 'call-session-123',
      displayName: 'Santa',
      callType: 'voice',
    );
    final expectedCall = IncomingCallDisplayInfo(
      callSessionId: 'call-session-123',
      displayName: 'Santa',
      callType: 'voice',
    );

    await manager.presentIncomingCall(call);

    expect(manager.presentedCalls, [expectedCall]);
  });

  test('publishes lifecycle events with the call session id', () async {
    final manager = _RecordingSystemCallManager();
    addTearDown(manager.dispose);

    final answered = expectLater(manager.onAnswered, emits('call-session-123'));
    final rejected = expectLater(manager.onRejected, emits('call-session-123'));
    final ended = expectLater(manager.onEnded, emits('call-session-123'));

    manager.emitAnswered('call-session-123');
    manager.emitRejected('call-session-123');
    manager.emitEnded('call-session-123');

    await Future.wait([answered, rejected, ended]);
  });

  test('reports answer and end results with the call session id', () async {
    final manager = _RecordingSystemCallManager();
    addTearDown(manager.dispose);

    await manager.answerSucceeded('call-session-success');
    await manager.answerFailed('call-session-failure');
    await manager.endCall('call-session-ended');

    expect(manager.answerSucceededCalls, ['call-session-success']);
    expect(manager.answerFailedCalls, ['call-session-failure']);
    expect(manager.endedCalls, ['call-session-ended']);
  });
}

final class _RecordingSystemCallManager implements SystemCallManager {
  final List<IncomingCallDisplayInfo> presentedCalls = [];
  final List<String> answerSucceededCalls = [];
  final List<String> answerFailedCalls = [];
  final List<String> endedCalls = [];
  final StreamController<String> _answered =
      StreamController<String>.broadcast();
  final StreamController<String> _rejected =
      StreamController<String>.broadcast();
  final StreamController<String> _ended = StreamController<String>.broadcast();
  final StreamController<String> _audioActivated =
      StreamController<String>.broadcast();

  @override
  Stream<String> get onAnswered => _answered.stream;

  @override
  Stream<String> get onRejected => _rejected.stream;

  @override
  Stream<String> get onEnded => _ended.stream;

  @override
  Stream<String> get onAudioActivated => _audioActivated.stream;

  @override
  Future<bool> isAudioActivated(String callSessionId) async => false;

  @override
  Future<void> presentIncomingCall(IncomingCallDisplayInfo call) async {
    presentedCalls.add(call);
  }

  @override
  Future<void> endCall(String callSessionId) async {
    endedCalls.add(callSessionId);
  }

  @override
  Future<void> answerSucceeded(String callSessionId) async {
    answerSucceededCalls.add(callSessionId);
  }

  @override
  Future<void> answerFailed(String callSessionId) async {
    answerFailedCalls.add(callSessionId);
  }

  void emitAnswered(String callSessionId) => _answered.add(callSessionId);

  void emitRejected(String callSessionId) => _rejected.add(callSessionId);

  void emitEnded(String callSessionId) => _ended.add(callSessionId);

  void emitAudioActivated(String callSessionId) =>
      _audioActivated.add(callSessionId);

  Future<void> dispose() async {
    await Future.wait([
      _answered.close(),
      _rejected.close(),
      _ended.close(),
      _audioActivated.close(),
    ]);
  }
}
