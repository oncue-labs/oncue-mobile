final class ReservationInput {
  const ReservationInput({
    required this.personaKey,
    required this.scenarioKey,
    required this.scenarioContext,
    required this.callGoal,
    required this.scheduledAtLocal,
    required this.timeZone,
  });

  final String personaKey;
  final String scenarioKey;
  final String scenarioContext;
  final String callGoal;
  final DateTime scheduledAtLocal;
  final String timeZone;

  Map<String, dynamic> toJson() {
    return {
      'personaKey': personaKey,
      'scenarioKey': scenarioKey,
      'scenarioContext': scenarioContext,
      'callGoal': callGoal,
      'scheduledAtLocal': _formatLocalDateTime(scheduledAtLocal),
      'timeZone': timeZone,
    };
  }
}

final class Reservation {
  const Reservation({
    required this.reservationId,
    required this.reservationStatus,
    required this.personaKey,
    required this.scenarioKey,
    required this.scenarioContext,
    required this.callGoal,
    required this.scheduledAtLocal,
    required this.timeZone,
    required this.scheduledAtUtc,
    required this.editableUntil,
    required this.createdAt,
    required this.callSessionId,
    required this.callStatus,
    required this.callOutcome,
    required this.endedAt,
  });

  final String reservationId;
  final String reservationStatus;
  final String personaKey;
  final String scenarioKey;
  final String? scenarioContext;
  final String? callGoal;
  final DateTime scheduledAtLocal;
  final String timeZone;
  final DateTime scheduledAtUtc;
  final DateTime editableUntil;
  final DateTime createdAt;
  final String? callSessionId;
  final String? callStatus;
  final String? callOutcome;
  final DateTime? endedAt;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservationId: json['reservationId'].toString(),
      reservationStatus: json['reservationStatus'] as String,
      personaKey: json['personaKey'] as String,
      scenarioKey: json['scenarioKey'] as String,
      scenarioContext: json['scenarioContext'] as String?,
      callGoal: json['callGoal'] as String?,
      scheduledAtLocal: DateTime.parse(json['scheduledAtLocal'] as String),
      timeZone: json['timeZone'] as String,
      scheduledAtUtc: DateTime.parse(json['scheduledAtUtc'] as String),
      editableUntil: DateTime.parse(json['editableUntil'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      callSessionId: _optionalString(json['callSessionId']),
      callStatus: json['callStatus'] as String?,
      callOutcome: json['callOutcome'] as String?,
      endedAt: _optionalDateTime(json['endedAt']),
    );
  }

  static String? _optionalString(Object? value) {
    return value?.toString();
  }

  static DateTime? _optionalDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}

String _formatLocalDateTime(DateTime value) {
  return value.toIso8601String().substring(0, 19);
}
