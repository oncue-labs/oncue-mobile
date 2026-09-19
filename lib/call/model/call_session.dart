final class CallSession {
  const CallSession({
    required this.callSessionId,
    required this.callStatus,
    required this.callOutcome,
    required this.createdAt,
    required this.endedAt,
  });

  final String callSessionId;
  final String callStatus;
  final String? callOutcome;
  final DateTime createdAt;
  final DateTime? endedAt;

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      callSessionId: json['callSessionId'].toString(),
      callStatus: json['callStatus'] as String,
      callOutcome: json['callOutcome'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: _parseOptionalDateTime(json['endedAt']),
    );
  }

  static DateTime? _parseOptionalDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}
