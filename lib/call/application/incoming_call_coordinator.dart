import 'dart:async';
import 'dart:developer' as developer;

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
  final StreamController<String> _callFinishedController =
      StreamController<String>.broadcast();
  final Set<String> _answerHandlingCallSessionIds = <String>{};
  String? _activeCallSessionId;
  bool _started = false;

  /// Emits the call session ID after the system call has ended locally.
  Stream<String> get onCallFinished => _callFinishedController.stream;

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
      _systemCallManager.onAudioActivated.listen(
        (callSessionId) => logCallDiagnostic(
          'incoming_call.audio_activated callSessionId=$callSessionId',
        ),
      ),
    );
  }

  Future<void> handleAnswered(String callSessionId) async {
    start();
    if (_activeCallSessionId == callSessionId ||
        !_answerHandlingCallSessionIds.add(callSessionId)) {
      logCallDiagnostic(
        'incoming_call.duplicate_answer_ignored callSessionId=$callSessionId',
      );
      return;
    }
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
      _answerHandlingCallSessionIds.remove(callSessionId);
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
      // CallKit owns iOS audio activation, while this coordinator owns the
      // authenticated signaling connection. A delayed native activation event
      // must not prevent a background call from reaching the voice server.
      await _systemCallManager.answerSucceeded(callSessionId);
      logCallDiagnostic(
        'incoming_call.answer_succeeded_sent callSessionId=$callSessionId',
      );
      await _waitForAudioActivation(callSessionId);
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
    } finally {
      _answerHandlingCallSessionIds.remove(callSessionId);
    }
  }

  Future<void> _waitForAudioActivation(String callSessionId) async {
    if (await _systemCallManager.isAudioActivated(callSessionId)) {
      logCallDiagnostic(
        'incoming_call.audio_already_activated callSessionId=$callSessionId',
      );
      return;
    }

    logCallDiagnostic(
      'incoming_call.waiting_for_audio_activation callSessionId=$callSessionId',
    );
    await _systemCallManager.onAudioActivated
        .firstWhere(
          (activatedCallSessionId) => activatedCallSessionId == callSessionId,
        )
        .timeout(const Duration(seconds: 5));
    logCallDiagnostic(
      'incoming_call.audio_activation_received callSessionId=$callSessionId',
    );
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
      final isActiveCall = _activeCallSessionId == callSessionId;
      if (isActiveCall) {
        _activeCallSessionId = null;
        await _callConnection.hangup();
      } else if (_activeCallSessionId == null) {
        await _callConnection.hangup();
      } else {
        logCallDiagnostic(
          'incoming_call.stale_rejection_ignored callSessionId=$callSessionId',
        );
      }
    }
  }

  Future<void> handleEnded(String callSessionId) async {
    final isActiveCall = _activeCallSessionId == callSessionId;
    if (isActiveCall) {
      _activeCallSessionId = null;
      await _callConnection.hangup();
    } else {
      // A delayed CallKit event from an older Flutter/app instance must not
      // terminate the currently active WebRTC call.
      logCallDiagnostic(
        'incoming_call.stale_end_ignored callSessionId=$callSessionId',
      );
    }
    if (!_callFinishedController.isClosed) {
      _callFinishedController.add(callSessionId);
    }
  }

  Future<void> dispose() async {
    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    _subscriptions.clear();
    _started = false;
    _activeCallSessionId = null;
    await _callConnection.hangup();
    await _callFinishedController.close();
  }

  Future<void> _ignoreStreamError(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // Native event streams must not receive an unhandled async exception.
    }
  }
}

void logCallDiagnostic(String message) {
  developer.log(message, name: 'oncue.call');
}
