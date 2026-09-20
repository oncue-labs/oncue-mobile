import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/common/design_system/widgets/status_chip.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_detail_page.dart';

void main() {
  testWidgets(
    'shows reservation details and enables editing before the deadline',
    (tester) async {
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
      expect(
        find.byKey(const ValueKey('edit-reservation-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('edit-reservation-button')));
      expect(editTapped, isTrue);
    },
  );

  testWidgets('renders the persona name heading at the mockup type scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(editableUntil: DateTime(2026, 9, 8, 20)),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 19),
        ),
      ),
    );

    final heading = tester.widget<Text>(
      find.text(MvpCallCombinations.all.first.personaName),
    );
    expect(heading.style?.fontSize, closeTo(22.7, 0.5));
    expect(heading.style?.fontWeight, FontWeight.w800);
  });

  testWidgets(
    'sizes the reservation status chip to its text, not the full row',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailPage(
            reservation: _reservation(editableUntil: DateTime(2026, 9, 8, 20)),
            combination: MvpCallCombinations.all.first,
            now: () => DateTime(2026, 9, 8, 19),
          ),
        ),
      );

      final chipSize = tester.getSize(find.byType(StatusChip));

      expect(chipSize.width, lessThan(150));
    },
  );

  testWidgets('disables editing after the five-minute deadline', (
    tester,
  ) async {
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

    expect(
      find.byKey(const ValueKey('local-test-call-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('local-test-call-button')));
    expect(testCallTapped, isTrue);
  });

  testWidgets('reloads the reservation when the app resumes after a call', (
    tester,
  ) async {
    var loadCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(
            editableUntil: DateTime(2026, 9, 8, 20),
            callStatus: null,
            callOutcome: null,
          ),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 19),
          loadReservation: () async {
            loadCount++;
            return _reservation(
              editableUntil: DateTime(2026, 9, 8, 20),
              callStatus: 'IN_CALL',
              callOutcome: 'SUCCEEDED',
              endedAt: DateTime.parse('2026-09-08T12:05:00Z'),
            );
          },
        ),
      ),
    );

    expect(find.text('준비 전'), findsOneWidget);
    expect(find.text('진행 중'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('완료'), findsNWidgets(2));
  });

  testWidgets('loads the latest reservation when the detail page opens', (
    tester,
  ) async {
    var loadCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(
            editableUntil: DateTime(2026, 9, 8, 20),
            callStatus: null,
            callOutcome: null,
          ),
          combination: MvpCallCombinations.all.first,
          loadReservation: () async {
            loadCount++;
            return _reservation(
              editableUntil: DateTime(2026, 9, 8, 20),
              callStatus: 'IN_CALL',
              callOutcome: 'SUCCEEDED',
              endedAt: DateTime.parse('2026-09-08T12:05:00Z'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(loadCount, 1);
    expect(find.text('완료'), findsNWidgets(2));
  });

  testWidgets('shows a successful ended call as completed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(
            editableUntil: DateTime(2026, 9, 8, 20),
            callStatus: 'IN_CALL',
            callOutcome: 'SUCCEEDED',
            endedAt: DateTime.parse('2026-09-08T12:05:00Z'),
          ),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 21),
        ),
      ),
    );

    expect(find.text('완료'), findsNWidgets(2));
  });

  testWidgets('uses call outcome to show completion without endedAt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(
            editableUntil: DateTime(2026, 9, 8, 20),
            callStatus: 'IN_CALL',
            callOutcome: 'SUCCEEDED',
          ),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 21),
        ),
      ),
    );

    expect(find.text('완료'), findsNWidgets(2));
  });

  testWidgets('reloads the reservation when a system call finishes', (
    tester,
  ) async {
    final callFinishedEvents = StreamController<String>.broadcast();
    var loadCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationDetailPage(
          reservation: _reservation(
            editableUntil: DateTime(2026, 9, 8, 20),
            callStatus: null,
            callOutcome: null,
          ),
          combination: MvpCallCombinations.all.first,
          now: () => DateTime(2026, 9, 8, 19),
          loadReservation: () async {
            loadCount++;
            return _reservation(
              editableUntil: DateTime(2026, 9, 8, 20),
              callStatus: 'IN_CALL',
              callOutcome: 'SUCCEEDED',
              endedAt: DateTime.parse('2026-09-08T12:05:00Z'),
            );
          },
          callFinishedEvents: callFinishedEvents.stream,
        ),
      ),
    );

    callFinishedEvents.add('321');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('완료'), findsNWidgets(2));

    await callFinishedEvents.close();
  });

  testWidgets(
    'retries the reservation reload until the call result is stored',
    (tester) async {
      final callFinishedEvents = StreamController<String>.broadcast();
      var loadCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailPage(
            reservation: _reservation(
              editableUntil: DateTime(2026, 9, 8, 20),
              callStatus: null,
              callOutcome: null,
            ),
            combination: MvpCallCombinations.all.first,
            loadReservation: () async {
              loadCount++;
              return _reservation(
                editableUntil: DateTime(2026, 9, 8, 20),
                callStatus: loadCount >= 3 ? 'IN_CALL' : null,
                callOutcome: loadCount >= 3 ? 'SUCCEEDED' : null,
                endedAt: loadCount >= 3
                    ? DateTime.parse('2026-09-08T12:05:00Z')
                    : null,
              );
            },
            callFinishedEvents: callFinishedEvents.stream,
          ),
        ),
      );
      await tester.pumpAndSettle();

      callFinishedEvents.add('321');
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(loadCount, 3);
      expect(find.text('완료'), findsNWidgets(2));

      await callFinishedEvents.close();
    },
  );
}

Reservation _reservation({
  required DateTime editableUntil,
  String? callStatus = 'RINGING',
  String? callOutcome,
  DateTime? endedAt,
}) {
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
    callStatus: callStatus,
    callOutcome: callOutcome,
    endedAt: endedAt,
  );
}
