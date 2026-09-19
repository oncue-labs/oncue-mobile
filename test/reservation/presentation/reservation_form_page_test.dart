import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_form_page.dart';

void main() {
  final combination = MvpCallCombinations.all.first;
  final scheduledAtLocal = DateTime(2026, 9, 8, 21);

  testWidgets('renders the persona name heading at the mockup type scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationFormPage(
          combination: combination,
          initialScheduledAtLocal: scheduledAtLocal,
          timeZone: 'Asia/Seoul',
          reservationService: _service(
            permissionStatus: CallPermissionStatus.ready,
          ),
        ),
      ),
    );

    final heading = tester.widget<Text>(find.text(combination.personaName));
    expect(heading.style?.fontSize, closeTo(22.7, 0.5));
    expect(heading.style?.fontWeight, FontWeight.w800);
  });

  testWidgets('shows both scenario input guides and the timing notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationFormPage(
          combination: combination,
          initialScheduledAtLocal: scheduledAtLocal,
          timeZone: 'Asia/Seoul',
          reservationService: _service(
            permissionStatus: CallPermissionStatus.ready,
          ),
        ),
      ),
    );

    final contextField = tester.widget<TextField>(
      find.byKey(const ValueKey('scenario-context-input')),
    );
    final goalField = tester.widget<TextField>(
      find.byKey(const ValueKey('call-goal-input')),
    );

    expect(
      contextField.decoration?.hintText,
      combination.scenarioContextPlaceholder,
    );
    expect(goalField.decoration?.hintText, combination.callGoalPlaceholder);
    expect(find.text('예약 시각은 정확히 보장되지 않을 수 있어요.'), findsOneWidget);
  });

  testWidgets('opens the permission guide instead of calling the API', (
    tester,
  ) async {
    final apiClient = _FakeReservationClient();
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationFormPage(
          combination: combination,
          initialScheduledAtLocal: scheduledAtLocal,
          timeZone: 'Asia/Seoul',
          reservationService: _service(
            permissionStatus: CallPermissionStatus.permissionRequired,
            apiClient: apiClient,
          ),
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reservation-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('통화 권한 안내'), findsOneWidget);
    expect(apiClient.createCount, 0);
  });

  testWidgets('sends the selected combination and form input to the service', (
    tester,
  ) async {
    final apiClient = _FakeReservationClient();
    Reservation? savedReservation;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationFormPage(
          combination: combination,
          initialScheduledAtLocal: scheduledAtLocal,
          timeZone: 'Asia/Seoul',
          reservationService: _service(
            permissionStatus: CallPermissionStatus.ready,
            apiClient: apiClient,
          ),
          onSaved: (reservation) => savedReservation = reservation,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('scenario-context-input')),
      '아이 이름은 민수예요.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('call-goal-input')),
      '민수가 빨리 잠들게 해 주세요.',
    );
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reservation-submit-button')));
    await tester.pumpAndSettle();

    expect(apiClient.createdInput?.personaKey, 'santa');
    expect(apiClient.createdInput?.scenarioKey, 'child-roleplay');
    expect(apiClient.createdInput?.scenarioContext, '아이 이름은 민수예요.');
    expect(apiClient.createdInput?.callGoal, '민수가 빨리 잠들게 해 주세요.');
    expect(savedReservation?.reservationId, '1001');
  });

  testWidgets('prefills and updates an existing reservation', (tester) async {
    final apiClient = _FakeReservationClient();
    Reservation? savedReservation;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationFormPage(
          combination: combination,
          reservationId: '1001',
          initialScenarioContext: '기존 아이 이름은 민수예요.',
          initialCallGoal: '기존 목표를 유지해 주세요.',
          initialScheduledAtLocal: scheduledAtLocal,
          timeZone: 'Asia/Seoul',
          reservationService: _service(
            permissionStatus: CallPermissionStatus.ready,
            apiClient: apiClient,
          ),
          onSaved: (reservation) => savedReservation = reservation,
        ),
      ),
    );

    expect(find.text('예약 수정'), findsOneWidget);
    expect(find.text('기존 아이 이름은 민수예요.'), findsOneWidget);
    expect(find.text('기존 목표를 유지해 주세요.'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reservation-submit-button')));
    await tester.pumpAndSettle();

    expect(apiClient.updatedReservationId, '1001');
    expect(apiClient.updatedInput?.scenarioContext, '기존 아이 이름은 민수예요.');
    expect(apiClient.updatedInput?.callGoal, '기존 목표를 유지해 주세요.');
    expect(savedReservation?.reservationId, '1001');
  });
}

ReservationService _service({
  required CallPermissionStatus permissionStatus,
  _FakeReservationClient? apiClient,
}) {
  return ReservationService(
    apiClient ?? _FakeReservationClient(),
    _FakeCallPermissionService(permissionStatus),
  );
}

final class _FakeCallPermissionService implements CallPermissionService {
  _FakeCallPermissionService(this.status);

  final CallPermissionStatus status;

  @override
  Future<CallPermissionStatus> checkRequiredPermissions() async => status;

  @override
  Future<CallPermissionStatus> requestMissingPermissions() async => status;

  @override
  Future<void> openSettings() async {}
}

final class _FakeReservationClient implements ReservationClient {
  int createCount = 0;
  ReservationInput? createdInput;
  String? updatedReservationId;
  ReservationInput? updatedInput;

  @override
  Future<Reservation> cancel(
    String reservationId, {
    String? accessToken,
  }) async => _reservation();

  @override
  Future<Reservation> create(
    ReservationInput input, {
    String? accessToken,
  }) async {
    createCount++;
    createdInput = input;
    return _reservation();
  }

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
  }) async {
    updatedReservationId = reservationId;
    updatedInput = input;
    return _reservation();
  }
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
