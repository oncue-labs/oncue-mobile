/// Data that is safe to show in the operating system's incoming call UI.
final class IncomingCallDisplayInfo {
  const IncomingCallDisplayInfo({
    required this.callSessionId,
    required this.displayName,
    required this.callType,
  });

  final String callSessionId;
  final String displayName;
  final String callType;

  @override
  bool operator ==(Object other) {
    return other is IncomingCallDisplayInfo &&
        other.callSessionId == callSessionId &&
        other.displayName == displayName &&
        other.callType == callType;
  }

  @override
  int get hashCode => Object.hash(callSessionId, displayName, callType);
}

/// Common contract implemented by iOS CallKit and the future Android adapter.
abstract interface class SystemCallManager {
  Stream<String> get onAnswered;

  Stream<String> get onRejected;

  Stream<String> get onEnded;

  /// CallKit has activated the iOS audio session for this answered call.
  Stream<String> get onAudioActivated;

  /// Returns whether CallKit already activated audio for this call.
  ///
  /// This closes the race where native CallKit emits `onAudioActivated`
  /// before Flutter starts waiting for the event.
  Future<bool> isAudioActivated(String callSessionId);

  Future<void> presentIncomingCall(IncomingCallDisplayInfo call);

  Future<void> endCall(String callSessionId);

  Future<void> answerSucceeded(String callSessionId);

  Future<void> answerFailed(String callSessionId);
}
