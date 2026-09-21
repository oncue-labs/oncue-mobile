import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/application/incoming_call_coordinator.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/call/model/call_session.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/call/system_call_manager.dart';

void main() {
  test(
    'activates CallKit audio before starting the answer connection',
    () async {
      final systemCallManager = _FakeSystemCallManager();
      final events = <String>[];
      final connection = _FakeCallConnection(
        onConnect: () => events.add('connect'),
      );
      systemCallManager.onAnswerSucceeded = () =>
          events.add('answer-succeeded');
      final coordinator = IncomingCallCoordinator(
        systemCallManager: systemCallManager,
        authSessionProvider: _FakeAuthSessionProvider(_session()),
        callSessionApi: _FakeCallSessionApi(),
        callConnection: connection,
      );

      await coordinator.handleAnswered('321');

      expect(connection.connectedCallSessionId, '321');
      expect(systemCallManager.succeededCallSessionIds, ['321']);
      expect(systemCallManager.failedCallSessionIds, isEmpty);
      expect(events, ['answer-succeeded', 'connect']);
    },
  );

  test(
    'starts the answer connection when CallKit audio activation is delayed',
    () async {
      final systemCallManager = _FakeSystemCallManager(
        emitAudioActivationOnAnswer: false,
      );
      final answerSucceeded = Completer<void>();
      systemCallManager.onAnswerSucceeded = answerSucceeded.complete;
      final connection = _FakeCallConnection();
      final coordinator = IncomingCallCoordinator(
        systemCallManager: systemCallManager,
        authSessionProvider: _FakeAuthSessionProvider(_session()),
        callSessionApi: _FakeCallSessionApi(),
        callConnection: connection,
      );

      final answer = coordinator.handleAnswered('321');
      await answerSucceeded.future;
      await Future<void>.delayed(Duration.zero);

      expect(connection.connectedCallSessionId, '321');

      systemCallManager.emitAudioActivated('321');
      await answer;

      expect(connection.connectedCallSessionId, '321');
    },
  );

  test(
    'connects when CallKit audio activation happened before answer handling',
    () async {
      final systemCallManager = _FakeSystemCallManager(
        emitAudioActivationOnAnswer: false,
      );
      systemCallManager.emitAudioActivated('321');
      final connection = _FakeCallConnection();
      final coordinator = IncomingCallCoordinator(
        systemCallManager: systemCallManager,
        authSessionProvider: _FakeAuthSessionProvider(_session()),
        callSessionApi: _FakeCallSessionApi(),
        callConnection: connection,
      );

      await coordinator.handleAnswered('321');

      expect(connection.connectedCallSessionId, '321');
    },
    timeout: const Timeout(Duration(seconds: 2)),
  );

  test('ends the system call when the answer connection fails', () async {
    final systemCallManager = _FakeSystemCallManager();
    final connection = _FakeCallConnection(
      connectError: StateError('no route'),
    );
    final coordinator = IncomingCallCoordinator(
      systemCallManager: systemCallManager,
      authSessionProvider: _FakeAuthSessionProvider(_session()),
      callSessionApi: _FakeCallSessionApi(),
      callConnection: connection,
    );

    await coordinator.handleAnswered('321');

    expect(systemCallManager.succeededCallSessionIds, ['321']);
    expect(systemCallManager.failedCallSessionIds, isEmpty);
    expect(systemCallManager.endedCallSessionIds, ['321']);
  });

  test(
    'rejects the call with the current access token and closes media',
    () async {
      final systemCallManager = _FakeSystemCallManager();
      final callSessionApi = _FakeCallSessionApi();
      final connection = _FakeCallConnection();
      final coordinator = IncomingCallCoordinator(
        systemCallManager: systemCallManager,
        authSessionProvider: _FakeAuthSessionProvider(_session()),
        callSessionApi: callSessionApi,
        callConnection: connection,
      );

      await coordinator.handleRejected('321');

      expect(callSessionApi.rejectedCallSessionId, '321');
      expect(callSessionApi.accessToken, 'access-token');
      expect(connection.hangupCount, 1);
    },
  );

  test('connects using a session that only finishes loading after the '
      'call is answered (VoIP cold-launch race)', () async {
    final systemCallManager = _FakeSystemCallManager();
    final connection = _FakeCallConnection();
    final coordinator = IncomingCallCoordinator(
      systemCallManager: systemCallManager,
      authSessionProvider: _FakeAuthSessionProvider(
        null,
        loadedSession: _session(),
      ),
      callSessionApi: _FakeCallSessionApi(),
      callConnection: connection,
    );

    await coordinator.handleAnswered('321');

    expect(connection.connectedCallSessionId, '321');
    expect(systemCallManager.failedCallSessionIds, isEmpty);
    expect(systemCallManager.endedCallSessionIds, isEmpty);
  });

  test('ends the active media connection when CallKit ends the call', () async {
    final connection = _FakeCallConnection();
    final coordinator = IncomingCallCoordinator(
      systemCallManager: _FakeSystemCallManager(),
      authSessionProvider: _FakeAuthSessionProvider(_session()),
      callSessionApi: _FakeCallSessionApi(),
      callConnection: connection,
    );

    await coordinator.handleAnswered('321');
    await coordinator.handleEnded('321');

    expect(connection.hangupCount, 1);
  });

  test('emits a call-finished event when CallKit ends the call', () async {
    final coordinator = IncomingCallCoordinator(
      systemCallManager: _FakeSystemCallManager(),
      authSessionProvider: _FakeAuthSessionProvider(_session()),
      callSessionApi: _FakeCallSessionApi(),
      callConnection: _FakeCallConnection(),
    );

    final finishedCallSessionId = coordinator.onCallFinished.first;
    await coordinator.handleEnded('321');

    expect(await finishedCallSessionId, '321');
    await coordinator.dispose();
  });
}

AuthSession _session() {
  return AuthSession(
    accessToken: 'access-token',
    expiresAt: DateTime.utc(2026, 9, 19, 12, 1),
    createdAt: DateTime.utc(2026, 9, 19, 12),
  );
}

final class _FakeAuthSessionProvider implements AuthSessionProvider {
  _FakeAuthSessionProvider(this.currentSession, {AuthSession? loadedSession})
    : _loadedSession = loadedSession ?? currentSession;

  @override
  final AuthSession? currentSession;
  final AuthSession? _loadedSession;

  @override
  Future<AuthSession?> ensureSessionLoaded() async {
    return currentSession ?? _loadedSession;
  }
}

final class _FakeCallConnection implements CallConnection {
  _FakeCallConnection({this.connectError, this.onConnect});

  final Object? connectError;
  final void Function()? onConnect;
  String? connectedCallSessionId;
  int hangupCount = 0;

  @override
  Future<void> connect(String callSessionId, {String? accessToken}) async {
    onConnect?.call();
    if (connectError != null) {
      throw connectError!;
    }
    connectedCallSessionId = callSessionId;
  }

  @override
  Future<void> hangup() async {
    hangupCount++;
  }
}

final class _FakeCallSessionApi implements CallSessionCommandApi {
  String? rejectedCallSessionId;
  String? accessToken;

  @override
  Future<CallSession> reject(
    String callSessionId, {
    String? accessToken,
  }) async {
    rejectedCallSessionId = callSessionId;
    this.accessToken = accessToken;
    return CallSession(
      callSessionId: callSessionId,
      callStatus: 'ENDED',
      callOutcome: 'REJECTED',
      createdAt: DateTime.utc(2026, 9, 19, 12),
      endedAt: DateTime.utc(2026, 9, 19, 12, 1),
    );
  }

  @override
  Future<CallSession> prepareTestCall(
    String reservationId, {
    String? accessToken,
  }) async {
    throw UnimplementedError();
  }
}

final class _FakeSystemCallManager implements SystemCallManager {
  _FakeSystemCallManager({this.emitAudioActivationOnAnswer = true});

  final bool emitAudioActivationOnAnswer;
  final _answered = StreamController<String>.broadcast();
  final _rejected = StreamController<String>.broadcast();
  final _ended = StreamController<String>.broadcast();
  final _audioActivated = StreamController<String>.broadcast();
  final _activatedAudioCallSessionIds = <String>{};
  final succeededCallSessionIds = <String>[];
  final failedCallSessionIds = <String>[];
  final endedCallSessionIds = <String>[];
  void Function()? onAnswerSucceeded;

  @override
  Stream<String> get onAnswered => _answered.stream;

  @override
  Stream<String> get onRejected => _rejected.stream;

  @override
  Stream<String> get onEnded => _ended.stream;

  @override
  Stream<String> get onAudioActivated => _audioActivated.stream;

  @override
  Future<bool> isAudioActivated(String callSessionId) async {
    return _activatedAudioCallSessionIds.contains(callSessionId);
  }

  @override
  Future<void> presentIncomingCall(IncomingCallDisplayInfo call) async {}

  @override
  Future<void> endCall(String callSessionId) async {
    endedCallSessionIds.add(callSessionId);
  }

  @override
  Future<void> answerSucceeded(String callSessionId) async {
    succeededCallSessionIds.add(callSessionId);
    onAnswerSucceeded?.call();
    if (emitAudioActivationOnAnswer) {
      emitAudioActivated(callSessionId);
    }
  }

  @override
  Future<void> answerFailed(String callSessionId) async {
    failedCallSessionIds.add(callSessionId);
  }

  void emitAudioActivated(String callSessionId) {
    _activatedAudioCallSessionIds.add(callSessionId);
    _audioActivated.add(callSessionId);
  }

  Future<void> dispose() async {
    await Future.wait([
      _answered.close(),
      _rejected.close(),
      _ended.close(),
      _audioActivated.close(),
    ]);
  }
}
