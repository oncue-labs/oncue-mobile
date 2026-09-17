import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

void main() {
  final combination = MvpCallCombinations.all.first;
  final scheduledAtLocal = DateTime(2026, 9, 8, 21);

  test(
    'creates a reservation from the selected combination after permission check',
    () async {
      final apiClient = _FakeReservationClient();
      final service = ReservationService(
        apiClient,
        _FakeCallPermissionService(CallPermissionStatus.ready),
      );

      await service.createFromCard(
        combination: combination,
        scenarioContext: '아이 이름은 민수예요.',
        callGoal: '민수가 빨리 잠들게 해 주세요.',
        scheduledAtLocal: scheduledAtLocal,
        timeZone: 'Asia/Seoul',
        accessToken: 'access-token',
      );

      expect(apiClient.createdInput?.personaKey, 'santa');
      expect(apiClient.createdInput?.scenarioKey, 'child-roleplay');
      expect(apiClient.createdInput?.scheduledAtLocal, scheduledAtLocal);
      expect(apiClient.createdInput?.timeZone, 'Asia/Seoul');
      expect(apiClient.createdAccessToken, 'access-token');
    },
  );

  test(
    'does not call the reservation API when required permission is missing',
    () async {
      final apiClient = _FakeReservationClient();
      final service = ReservationService(
        apiClient,
        _FakeCallPermissionService(CallPermissionStatus.permissionRequired),
      );

      await expectLater(
        service.createFromCard(
          combination: combination,
          scenarioContext: '아이 이름은 민수예요.',
          callGoal: '민수가 빨리 잠들게 해 주세요.',
          scheduledAtLocal: scheduledAtLocal,
          timeZone: 'Asia/Seoul',
        ),
        throwsA(
          isA<CallPermissionRequiredException>().having(
            (error) => error.status,
            'status',
            CallPermissionStatus.permissionRequired,
          ),
        ),
      );

      expect(apiClient.createCount, 0);
    },
  );

  test(
    'updates a reservation with the selected combination and current input',
    () async {
      final apiClient = _FakeReservationClient();
      final service = ReservationService(
        apiClient,
        _FakeCallPermissionService(CallPermissionStatus.ready),
      );

      await service.edit(
        reservationId: '1001',
        combination: combination,
        scenarioContext: '새로운 컨텍스트',
        callGoal: '새로운 목표',
        scheduledAtLocal: scheduledAtLocal,
        timeZone: 'Asia/Seoul',
      );

      expect(apiClient.updatedReservationId, '1001');
      expect(apiClient.updatedInput?.callGoal, '새로운 목표');
    },
  );

  test('loads the authenticated user reservation list', () async {
    final apiClient = _FakeReservationClient();
    final service = ReservationService(
      apiClient,
      _FakeCallPermissionService(CallPermissionStatus.ready),
    );

    final reservations = await service.list(accessToken: 'access-token');

    expect(reservations, hasLength(1));
    expect(apiClient.listAccessToken, 'access-token');
  });

  test('loads an authenticated reservation detail', () async {
    final apiClient = _FakeReservationClient();
    final service = ReservationService(
      apiClient,
      _FakeCallPermissionService(CallPermissionStatus.ready),
    );

    final reservation = await service.get('1001', accessToken: 'access-token');

    expect(reservation.reservationId, '1001');
    expect(apiClient.loadedReservationId, '1001');
    expect(apiClient.loadedAccessToken, 'access-token');
  });
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
  ReservationInput? createdInput;
  String? createdAccessToken;
  int createCount = 0;
  String? updatedReservationId;
  ReservationInput? updatedInput;
  String? listAccessToken;
  String? loadedReservationId;
  String? loadedAccessToken;

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
    createdAccessToken = accessToken;
    return _reservation();
  }

  @override
  Future<Reservation> get(String reservationId, {String? accessToken}) async {
    loadedReservationId = reservationId;
    loadedAccessToken = accessToken;
    return _reservation();
  }

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
    scenarioContext: '컨텍스트',
    callGoal: '목표',
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
