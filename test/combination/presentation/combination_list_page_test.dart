import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_form_page.dart';
import 'package:oncue_mobile/combination/presentation/combination_list_page.dart';

void main() {
  testWidgets('shows the four MVP call combination cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(combinations: MvpCallCombinations.all),
      ),
    );

    expect(MvpCallCombinations.all, hasLength(4));
    expect(
      find.byKey(const ValueKey('combination-card-santa-child-roleplay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('combination-card-princess-child-roleplay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('combination-card-friend-go-home')),
      findsOneWidget,
    );
    expect(find.text('산타'), findsOneWidget);
    expect(find.text('공주'), findsOneWidget);
    expect(find.text('친구'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(
          'combination-card-friend-travel-friend-introduction',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('여행 동행 친구'), findsOneWidget);
  });

  testWidgets('limits card summaries to two lines with ellipsis', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(combinations: MvpCallCombinations.all),
      ),
    );

    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('summary-santa-child-roleplay')),
    );

    expect(summary.maxLines, 2);
    expect(summary.overflow, TextOverflow.ellipsis);
  });

  testWidgets('opens the selected combination detail with both input guides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(combinations: MvpCallCombinations.all),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('combination-card-friend-go-home')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detail-persona-friend')), findsOneWidget);
    expect(
      find.byType(BackButton),
      findsOneWidget,
      reason: 'the pushed detail screen must offer a way back to the list',
    );
    final heading = tester.widget<Text>(
      find.byKey(const ValueKey('detail-persona-friend')),
    );
    expect(heading.style?.fontSize, closeTo(22.7, 0.5));
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('scenario-context-input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('call-goal-input')), findsOneWidget);
    expect(find.text('10초 미리듣기'), findsOneWidget);
  });

  testWidgets('opens the reservation form with the device time zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(
          combinations: [MvpCallCombinations.all.first],
          reservationService: _reservationService(),
          timeZoneProvider: _FixedTimeZoneProvider('Asia/Seoul'),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('combination-card-santa-child-roleplay')),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('scenario-context-input')),
      '아이 이름은 민수예요.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('call-goal-input')),
      '민수가 빨리 잠들게 해 주세요.',
    );
    await tester.tap(find.byKey(const ValueKey('reserve-combination-button')));
    await tester.pumpAndSettle();

    expect(
      find.byType(BackButton),
      findsOneWidget,
      reason: 'the pushed reservation form must offer a way back',
    );
    final form = tester.widget<ReservationFormPage>(
      find.byType(ReservationFormPage),
    );
    expect(form.timeZone, 'Asia/Seoul');
    expect(form.initialScenarioContext, '아이 이름은 민수예요.');
    expect(form.initialCallGoal, '민수가 빨리 잠들게 해 주세요.');
    expect(find.text('통화 예약'), findsOneWidget);
  });
}

final class _FixedTimeZoneProvider implements DeviceTimeZoneProvider {
  _FixedTimeZoneProvider(this.timeZone);

  final String timeZone;

  @override
  Future<String> currentTimeZone() async => timeZone;
}

ReservationService _reservationService() {
  return ReservationService(
    _FakeReservationClient(),
    _ReadyCallPermissionService(),
  );
}

final class _ReadyCallPermissionService implements CallPermissionService {
  @override
  Future<CallPermissionStatus> checkRequiredPermissions() async {
    return CallPermissionStatus.ready;
  }

  @override
  Future<CallPermissionStatus> requestMissingPermissions() async {
    return CallPermissionStatus.ready;
  }

  @override
  Future<void> openSettings() async {}
}

final class _FakeReservationClient implements ReservationClient {
  @override
  Future<Reservation> cancel(
    String reservationId, {
    String? accessToken,
  }) async => _reservation();

  @override
  Future<Reservation> create(
    ReservationInput input, {
    String? accessToken,
  }) async => _reservation();

  @override
  Future<Reservation> get(String reservationId, {String? accessToken}) async =>
      _reservation();

  @override
  Future<List<Reservation>> list({String? accessToken}) async => [
    _reservation(),
  ];

  @override
  Future<Reservation> update(
    String reservationId,
    ReservationInput input, {
    String? accessToken,
  }) async => _reservation();
}

Reservation _reservation() {
  return Reservation(
    reservationId: '1001',
    reservationStatus: 'SCHEDULED',
    personaKey: 'santa',
    scenarioKey: 'child-roleplay',
    scenarioContext: null,
    callGoal: null,
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
