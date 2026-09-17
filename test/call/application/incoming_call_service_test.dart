import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/application/incoming_call_service.dart';
import 'package:oncue_mobile/common/call/system_call_manager.dart';

void main() {
  test(
    'reports a valid VoIP payload with only safe display information',
    () async {
      final manager = _RecordingSystemCallManager();
      addTearDown(manager.dispose);
      final service = IncomingCallService(manager);

      await service.handleVoipPayload({
        'callSessionId': 12345,
        'displayName': '산타',
        'callType': 'voice',
        'scenarioContext': '민수에게 비밀로 해 주세요.',
        'connectionToken': 'must-not-be-used',
      });

      expect(manager.presentedCalls, [
        const IncomingCallDisplayInfo(
          callSessionId: '12345',
          displayName: '산타',
          callType: 'voice',
        ),
      ]);
    },
  );

  test('ignores an invalid VoIP payload', () async {
    final manager = _RecordingSystemCallManager();
    addTearDown(manager.dispose);
    final service = IncomingCallService(manager);

    await service.handleVoipPayload({'callSessionId': 12345});
    await service.handleVoipPayload({'displayName': '산타'});
    await service.handleVoipPayload({
      'callSessionId': ' ',
      'displayName': '산타',
    });

    expect(manager.presentedCalls, isEmpty);
  });

  test('does not report the same call twice', () async {
    final manager = _RecordingSystemCallManager();
    addTearDown(manager.dispose);
    final service = IncomingCallService(manager);
    final payload = {'callSessionId': 12345, 'displayName': '산타'};

    await service.handleVoipPayload(payload);
    await service.handleVoipPayload(payload);

    expect(manager.presentedCalls, hasLength(1));
  });

  test('allows a retry when system call registration fails', () async {
    final manager = _RecordingSystemCallManager(failNextPresentation: true);
    addTearDown(manager.dispose);
    final service = IncomingCallService(manager);
    final payload = {'callSessionId': 12345, 'displayName': '산타'};

    await expectLater(
      service.handleVoipPayload(payload),
      throwsA(isA<SystemCallRegistrationException>()),
    );
    await service.handleVoipPayload(payload);

    expect(manager.presentedCalls, hasLength(1));
  });

  test('forwards system call lifecycle events', () async {
    final manager = _RecordingSystemCallManager();
    addTearDown(manager.dispose);
    final service = IncomingCallService(manager);

    final answered = expectLater(service.onAnswered, emits('12345'));
    final rejected = expectLater(service.onRejected, emits('12345'));
    final ended = expectLater(service.onEnded, emits('12345'));

    manager.emitAnswered('12345');
    manager.emitRejected('12345');
    manager.emitEnded('12345');

    await Future.wait([answered, rejected, ended]);
  });
}

final class _RecordingSystemCallManager implements SystemCallManager {
  _RecordingSystemCallManager({this.failNextPresentation = false});

  final bool failNextPresentation;
  final List<IncomingCallDisplayInfo> presentedCalls = [];
  final StreamController<String> _answered =
      StreamController<String>.broadcast();
  final StreamController<String> _rejected =
      StreamController<String>.broadcast();
  final StreamController<String> _ended = StreamController<String>.broadcast();
  bool _shouldFailPresentation = false;

  @override
  Stream<String> get onAnswered => _answered.stream;

  @override
  Stream<String> get onRejected => _rejected.stream;

  @override
  Stream<String> get onEnded => _ended.stream;

  @override
  Future<void> presentIncomingCall(IncomingCallDisplayInfo call) async {
    if (failNextPresentation && !_shouldFailPresentation) {
      _shouldFailPresentation = true;
      throw StateError('CallKit registration failed');
    }
    presentedCalls.add(call);
  }

  @override
  Future<void> endCall(String callSessionId) async {}

  @override
  Future<void> answerSucceeded(String callSessionId) async {}

  @override
  Future<void> answerFailed(String callSessionId) async {}

  void emitAnswered(String callSessionId) => _answered.add(callSessionId);

  void emitRejected(String callSessionId) => _rejected.add(callSessionId);

  void emitEnded(String callSessionId) => _ended.add(callSessionId);

  Future<void> dispose() async {
    await Future.wait([_answered.close(), _rejected.close(), _ended.close()]);
  }
}
