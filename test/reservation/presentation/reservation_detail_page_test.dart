import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_detail_page.dart';

void main() {
  testWidgets('shows reservation details and enables editing before the deadline', (
    tester,
  ) async {
    var editTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(editableUntil: DateTime(2026, 9, 8, 20)),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 19),
          onEdit: () async => editTapped = true,
        ),
      ),
    );

    expect(find.text('예약됨'), findsOneWidget);
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(find.text('시나리오 컨텍스트'), findsOneWidget);
    expect(find.text('아이 이름은 민수예요.'), findsOneWidget);
    expect(find.text('통화 목표'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-reservation-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-reservation-button')));
    expect(editTapped, isTrue);
  });

  testWidgets('disables editing after the five-minute deadline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(editableUntil: DateTime(2026, 9, 8, 20)),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 20, 1),
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    final editButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('edit-reservation-button')),
    );
    expect(editButton.onPressed, isNull);
    expect(find.text('통화 5분 전부터는 예약을 수정할 수 없습니다.'), findsOneWidget);
  });

  testWidgets('shows the local immediate-call action only when provided', (
    tester,
  ) async {
    var testCallTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(editableUntil: DateTime(2026, 9, 8, 20)),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 19),
          onStartTestCall: () async => testCallTapped = true,
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(find.byKey(const ValueKey('local-test-call-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('local-test-call-button')));
    expect(testCallTapped, isTrue);
  });
}

Reservation _reservation({required DateTime editableUntil}) {
  return Reservation(
    reservationId: '1001',
    reservationStatus: 'SCHEDULED',
    personaKey: 'santa',
    scenarioKey: 'child-roleplay',
    scenarioContext: '아이 이름은 민수예요.',
    callGoal: '민수가 빨리 잠들게 해 주세요.',
    scheduledAtLocal: DateTime(2026, 9, 8, 21),
    timeZone: 'Asia/Seoul',
    scheduledAtUtc: DateTime.parse('2026-09-08T12:00:00Z'),
    editableUntil: editableUntil,
    createdAt: DateTime.parse('2026-09-08T10:00:00Z'),
    callSessionId: null,
    callStatus: 'RINGING',
    callOutcome: null,
    endedAt: null,
  );
}
