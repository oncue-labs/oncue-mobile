import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_detail_page.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_form_page.dart';
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

  testWidgets('shows an empty state when there are no reservations', (
    tester,
  ) async {
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

  testWidgets('opens the reservation edit form from reservation details', (
    tester,
  ) async {
    final reservation = _reservation();
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationListPage(
          loadReservations: () async => [reservation],
          combinations: MvpCallCombinations.all,
          reservationService: _reservationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reservation-1001')));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-reservation-button')));
    await tester.pumpAndSettle();

    expect(find.text('예약 수정'), findsOneWidget);
    expect(find.byType(ReservationFormPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reservation-submit-button')),
      findsOneWidget,
    );
    expect(find.text('아이 이름은 민수예요.'), findsOneWidget);
    expect(find.text('민수가 빨리 잠들게 해 주세요.'), findsOneWidget);
  });

  testWidgets('confirms and cancels a reservation from its details', (
    tester,
  ) async {
    final reservationClient = _FakeReservationClient();
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationListPage(
          loadReservations: () async => [_reservation()],
          combinations: MvpCallCombinations.all,
          reservationService: ReservationService(
            reservationClient,
            _ReadyCallPermissionService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reservation-1001')));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cancel-reservation-button')));
    await tester.pumpAndSettle();

    expect(find.text('예약을 취소할까요?'), findsOneWidget);
    await tester.tap(find.text('예약 취소').last);
    await tester.pumpAndSettle();

    expect(reservationClient.cancelCount, 1);
    expect(find.text('예약 목록'), findsOneWidget);
  });
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
  int cancelCount = 0;

  @override
  Future<Reservation> cancel(
    String reservationId, {
    String? accessToken,
  }) async {
    cancelCount++;
    return _reservation();
  }

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
    scenarioContext: '아이 이름은 민수예요.',
    callGoal: '민수가 빨리 잠들게 해 주세요.',
    scheduledAtLocal: DateTime(2026, 9, 8, 21),
    timeZone: 'Asia/Seoul',
    scheduledAtUtc: DateTime.parse('2026-09-08T12:00:00Z'),
    editableUntil: DateTime.now().add(const Duration(hours: 1)),
    createdAt: DateTime.parse('2026-09-08T10:00:00Z'),
    callSessionId: null,
    callStatus: null,
    callOutcome: null,
    endedAt: null,
  );
}
