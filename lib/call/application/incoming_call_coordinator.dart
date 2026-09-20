import 'dart:async';

import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/common/call/system_call_manager.dart';

/// Bridges operating-system call actions to the authenticated call flow.
///
/// CallKit owns the visible incoming-call UI. This coordinator owns what the
/// app must do after the user answers, rejects, or ends that system call.
final class IncomingCallCoordinator {
  IncomingCallCoordinator({
    required SystemCallManager systemCallManager,
    required AuthSessionProvider authSessionProvider,
    required CallSessionCommandApi callSessionApi,
    required CallConnection callConnection,
  }) : _systemCallManager = systemCallManager,
       _authSessionProvider = authSessionProvider,
       _callSessionApi = callSessionApi,
       _callConnection = callConnection;

  final SystemCallManager _systemCallManager;
  final AuthSessionProvider _authSessionProvider;
  final CallSessionCommandApi _callSessionApi;
  final CallConnection _callConnection;
  final List<StreamSubscription<String>> _subscriptions = [];
  final Set<String> _activatedAudioCallSessionIds = <String>{};
  final Map<String, List<Completer<void>>> _audioActivationWaiters = {};
  String? _activeCallSessionId;
  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _subscriptions.add(
      _systemCallManager.onAnswered.listen(
        (callSessionId) =>
            unawaited(_ignoreStreamError(handleAnswered(callSessionId))),
      ),
    );
    _subscriptions.add(
      _systemCallManager.onRejected.listen(
        (callSessionId) =>
            unawaited(_ignoreStreamError(handleRejected(callSessionId))),
      ),
    );
    _subscriptions.add(
      _systemCallManager.onEnded.listen(
        (callSessionId) =>
            unawaited(_ignoreStreamError(handleEnded(callSessionId))),
      ),
    );
    _subscriptions.add(
      _systemCallManager.onAudioActivated.listen(_handleAudioActivated),
    );
  }

  Future<void> handleAnswered(String callSessionId) async {
    start();
    logCallDiagnostic('incoming_call.answered callSessionId=$callSessionId');
    // A VoIP push can cold-launch the app straight into call handling,
    // before the UI's own session restore has finished. Ensure the session
    // is loaded here instead of trusting currentSession, or a real login
    // gets treated as logged-out and the call is dropped immediately.
    final session = await _authSessionProvider.ensureSessionLoaded();
    if (session == null) {
      logCallDiagnostic(
        'incoming_call.no_session callSessionId=$callSessionId',
      );
      await _systemCallManager.answerFailed(callSessionId);
      return;
    }
    logCallDiagnostic(
      'incoming_call.session_loaded callSessionId=$callSessionId',
    );

    if (_activeCallSessionId != null && _activeCallSessionId != callSessionId) {
      await _callConnection.hangup();
    }
    _activeCallSessionId = callSessionId;

    try {
      // CallKit activates iOS's audio session only after the answer action is
      // fulfilled. WebRTC must start after that activation, not before it.
      await _systemCallManager.answerSucceeded(callSessionId);
      logCallDiagnostic(
        'incoming_call.answer_succeeded_sent callSessionId=$callSessionId',
      );
      await _waitForAudioActivation(callSessionId);
      logCallDiagnostic(
        'incoming_call.audio_activation_confirmed callSessionId=$callSessionId',
      );
      await _callConnection.connect(
        callSessionId,
        accessToken: session.accessToken,
      );
    } catch (error) {
      logCallDiagnostic(
        'incoming_call.failed callSessionId=$callSessionId error=$error',
      );
      _activeCallSessionId = null;
      await _callConnection.hangup();
      await _systemCallManager.endCall(callSessionId);
    }
  }

  Future<void> handleRejected(String callSessionId) async {
    final session = _authSessionProvider.currentSession;
    try {
      if (session != null) {
        await _callSessionApi.reject(
          callSessionId,
          accessToken: session.accessToken,
        );
      }
    } finally {
      if (_activeCallSessionId == callSessionId) {
        _activeCallSessionId = null;
      }
      await _callConnection.hangup();
    }
  }

  Future<void> handleEnded(String callSessionId) async {
    if (_activeCallSessionId == callSessionId) {
      _activeCallSessionId = null;
    }
    await _callConnection.hangup();
  }

  Future<void> dispose() async {
    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    _subscriptions.clear();
    _activatedAudioCallSessionIds.clear();
    _audioActivationWaiters.clear();
    _started = false;
    _activeCallSessionId = null;
    await _callConnection.hangup();
  }

  void _handleAudioActivated(String callSessionId) {
    final waiters = _audioActivationWaiters.remove(callSessionId);
    if (waiters == null || waiters.isEmpty) {
      _activatedAudioCallSessionIds.add(callSessionId);
      return;
    }
    for (final waiter in waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
  }

  Future<void> _waitForAudioActivation(String callSessionId) async {
    if (await _systemCallManager.isAudioActivated(callSessionId)) {
      return;
    }
    if (_activatedAudioCallSessionIds.remove(callSessionId)) {
      return Future<void>.value();
    }

    final waiter = Completer<void>();
    _audioActivationWaiters
        .putIfAbsent(callSessionId, () => <Completer<void>>[])
        .add(waiter);
    // A cold VoIP launch on a locked device can leave CallKit noticeably
    // slower to activate the audio session than a warm foreground answer.
    // Measured activation has landed as late as ~16s after answering in
    // that exact condition (device logs), so 15s was still cutting it off
    // a second early. 25s gives real headroom above the observed worst case.
    await waiter.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw StateError(
        'CallKit audio session was not activated for $callSessionId.',
      ),
    );
  }

  Future<void> _ignoreStreamError(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // Native event streams must not receive an unhandled async exception.
    }
  }
}
