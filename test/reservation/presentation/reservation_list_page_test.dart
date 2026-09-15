import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_detail_page.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_list_page.dart';

void main() {
  testWidgets('loads reservations and opens the selected reservation detail', (
    tester,
  ) async {
    final reservation = _reservation();
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationListPage(
          loadReservations: () async => [reservation],
          combinations: MvpCallCombinations.all,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('산타'), findsOneWidget);
    expect(find.textContaining('예약됨'), findsOneWidget);
    expect(find.byKey(const ValueKey('reservation-1001')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reservation-1001')));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(find.byType(ReservationDetailPage), findsOneWidget);
    expect(find.text('아이 이름은 민수예요.'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no reservations', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationListPage(
          loadReservations: () async => [],
          combinations: MvpCallCombinations.all,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('예약된 통화가 없습니다.'), findsOneWidget);
  });
}

Reservation _reservation() {
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
    editableUntil: DateTime.parse('2026-09-08T11:55:00Z'),
    createdAt: DateTime.parse('2026-09-08T10:00:00Z'),
    callSessionId: null,
    callStatus: null,
    callOutcome: null,
    endedAt: null,
  );
}
