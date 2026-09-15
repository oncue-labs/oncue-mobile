import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

void main() {
  test('maps the reservation and optional call state from the API response', () {
    final reservation = Reservation.fromJson({
      'reservationId': 1001,
      'reservationStatus': 'SCHEDULED',
      'personaKey': 'santa',
      'scenarioKey': 'child-roleplay',
      'scenarioContext': '아이 이름은 민수예요.',
      'callGoal': '민수가 빨리 잠들게 해 주세요.',
      'scheduledAtLocal': '2026-09-08T21:00:00',
      'timeZone': 'Asia/Seoul',
      'scheduledAtUtc': '2026-09-08T12:00:00Z',
      'editableUntil': '2026-09-08T11:55:00Z',
      'createdAt': '2026-09-08T10:00:00Z',
      'callSessionId': 2001,
      'callStatus': 'RINGING',
      'callOutcome': null,
      'endedAt': null,
    });

    expect(reservation.reservationId, '1001');
    expect(reservation.reservationStatus, 'SCHEDULED');
    expect(reservation.personaKey, 'santa');
    expect(reservation.scenarioKey, 'child-roleplay');
    expect(reservation.scenarioContext, '아이 이름은 민수예요.');
    expect(reservation.callGoal, '민수가 빨리 잠들게 해 주세요.');
    expect(
      reservation.scheduledAtLocal,
      DateTime.parse('2026-09-08T21:00:00'),
    );
    expect(reservation.timeZone, 'Asia/Seoul');
    expect(
      reservation.scheduledAtUtc,
      DateTime.parse('2026-09-08T12:00:00Z'),
    );
    expect(
      reservation.editableUntil,
      DateTime.parse('2026-09-08T11:55:00Z'),
    );
    expect(reservation.callSessionId, '2001');
    expect(reservation.callStatus, 'RINGING');
    expect(reservation.callOutcome, isNull);
    expect(reservation.endedAt, isNull);
  });

  test('serializes local reservation input without converting it to UTC', () {
    final input = ReservationInput(
      personaKey: 'friend',
      scenarioKey: 'go-home',
      scenarioContext: '친구와 약속 중이에요.',
      callGoal: '집에 돌아가게 해 주세요.',
      scheduledAtLocal: DateTime(2026, 9, 8, 21),
      timeZone: 'Asia/Seoul',
    );

    expect(input.toJson(), {
      'personaKey': 'friend',
      'scenarioKey': 'go-home',
      'scenarioContext': '친구와 약속 중이에요.',
      'callGoal': '집에 돌아가게 해 주세요.',
      'scheduledAtLocal': '2026-09-08T21:00:00',
      'timeZone': 'Asia/Seoul',
    });
  });
}
