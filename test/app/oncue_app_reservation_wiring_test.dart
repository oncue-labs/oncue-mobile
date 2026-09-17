import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/app/oncue_app.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

void main() {
  testWidgets('loads reservations through the configured service', (
    tester,
  ) async {
    final client = _FakeReservationClient();
    final service = ReservationService(client, _ReadyPermissionService());

    await tester.pumpWidget(
      OnCueApp(
        accessToken: 'access-token',
        reservationService: service,
        timeZoneProvider: _FakeTimeZoneProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reservation-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reservation-1001')), findsOneWidget);
    expect(client.listAccessToken, 'access-token');
  });
}

final class _ReadyPermissionService implements CallPermissionService {
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

final class _FakeTimeZoneProvider implements DeviceTimeZoneProvider {
  @override
  Future<String> currentTimeZone() async => 'Asia/Seoul';
}

final class _FakeReservationClient implements ReservationClient {
  String? listAccessToken;

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
  Future<List<Reservation>> list({String? accessToken}) async {
    listAccessToken = accessToken;
    return [_reservation()];
  }

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
    editableUntil: DateTime.parse('2026-09-08T11:55:00Z'),
    createdAt: DateTime.parse('2026-09-08T10:00:00Z'),
    callSessionId: null,
    callStatus: null,
    callOutcome: null,
    endedAt: null,
  );
}
