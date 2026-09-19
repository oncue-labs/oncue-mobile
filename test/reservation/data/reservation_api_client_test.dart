import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

void main() {
  final input = ReservationInput(
    personaKey: 'santa',
    scenarioKey: 'child-roleplay',
    scenarioContext: '아이 이름은 민수예요.',
    callGoal: '민수가 빨리 잠들게 해 주세요.',
    scheduledAtLocal: DateTime(2026, 9, 8, 21),
    timeZone: 'Asia/Seoul',
  );

  test('creates a reservation with the confirmed request contract', () async {
    final apiClient = _RecordingApiClient(response: _reservationJson());
    final client = ReservationApiClient(apiClient);

    final reservation = await client.create(input, accessToken: 'access-token');

    expect(apiClient.method, 'POST');
    expect(apiClient.path, '/api/v1/reservations');
    expect(apiClient.body, input.toJson());
    expect(apiClient.accessToken, 'access-token');
    expect(reservation.reservationId, '1001');
  });

  test('lists the authenticated user reservations', () async {
    final apiClient = _RecordingApiClient(
      response: [_reservationJson(), _reservationJson(id: 1002)],
    );
    final client = ReservationApiClient(apiClient);

    final reservations = await client.list(accessToken: 'access-token');

    expect(apiClient.method, 'GET');
    expect(apiClient.path, '/api/v1/reservations');
    expect(apiClient.accessToken, 'access-token');
    expect(reservations.map((item) => item.reservationId), ['1001', '1002']);
  });

  test('gets one reservation by id', () async {
    final apiClient = _RecordingApiClient(response: _reservationJson());
    final client = ReservationApiClient(apiClient);

    await client.get('1001');

    expect(apiClient.method, 'GET');
    expect(apiClient.path, '/api/v1/reservations/1001');
  });

  test('updates a reservation with the confirmed PATCH endpoint', () async {
    final apiClient = _RecordingApiClient(response: _reservationJson());
    final client = ReservationApiClient(apiClient);

    await client.update('1001', input, accessToken: 'access-token');

    expect(apiClient.method, 'PATCH');
    expect(apiClient.path, '/api/v1/reservations/1001');
    expect(apiClient.body, input.toJson());
    expect(apiClient.accessToken, 'access-token');
  });

  test('cancels a reservation without deleting its record', () async {
    final apiClient = _RecordingApiClient(
      response: _reservationJson(reservationStatus: 'CANCELLED'),
    );
    final client = ReservationApiClient(apiClient);

    final reservation = await client.cancel(
      '1001',
      accessToken: 'access-token',
    );

    expect(apiClient.method, 'POST');
    expect(apiClient.path, '/api/v1/reservations/1001/cancel');
    expect(apiClient.body, isNull);
    expect(reservation.reservationStatus, 'CANCELLED');
  });
}

Map<String, dynamic> _reservationJson({
  int id = 1001,
  String reservationStatus = 'SCHEDULED',
}) {
  return {
    'reservationId': id,
    'reservationStatus': reservationStatus,
    'personaKey': 'santa',
    'scenarioKey': 'child-roleplay',
    'scenarioContext': '아이 이름은 민수예요.',
    'callGoal': '민수가 빨리 잠들게 해 주세요.',
    'scheduledAtLocal': '2026-09-08T21:00:00',
    'timeZone': 'Asia/Seoul',
    'scheduledAtUtc': '2026-09-08T12:00:00Z',
    'editableUntil': '2026-09-08T11:55:00Z',
    'createdAt': '2026-09-08T10:00:00Z',
    'callSessionId': null,
    'callStatus': null,
    'callOutcome': null,
    'endedAt': null,
  };
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final Object? response;
  String? method;
  String? path;
  Map<String, dynamic>? body;
  String? accessToken;

  @override
  Future<Object?> getJson(String requestPath, {String? accessToken}) async {
    method = 'GET';
    path = requestPath;
    this.accessToken = accessToken;
    return response;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    method = 'PATCH';
    path = requestPath;
    body = requestBody;
    this.accessToken = accessToken;
    return response! as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Object?> deleteJson(String requestPath, {String? accessToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    method = 'POST';
    path = requestPath;
    body = requestBody;
    this.accessToken = accessToken;
    return response! as Map<String, dynamic>;
  }
}
