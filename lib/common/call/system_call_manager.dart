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
}

/// Common contract implemented by iOS CallKit and the future Android adapter.
abstract interface class SystemCallManager {
  Stream<String> get onAnswered;

  Stream<String> get onRejected;

  Stream<String> get onEnded;

  Future<void> presentIncomingCall(IncomingCallDisplayInfo call);

  Future<void> endCall(String callSessionId);

  Future<void> answerSucceeded(String callSessionId);

  Future<void> answerFailed(String callSessionId);
}
