import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

abstract interface class ReservationClient {
  Future<Reservation> create(
    ReservationInput input, {
    String? accessToken,
  });

  Future<List<Reservation>> list({String? accessToken});

  Future<Reservation> get(
    String reservationId, {
    String? accessToken,
  });

  Future<Reservation> update(
    String reservationId,
    ReservationInput input, {
    String? accessToken,
  });

  Future<Reservation> cancel(
    String reservationId, {
    String? accessToken,
  });
}

final class ReservationApiClient implements ReservationClient {
  ReservationApiClient(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Reservation> create(
    ReservationInput input, {
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/reservations',
      requestBody: input.toJson(),
      accessToken: accessToken,
    );
    return Reservation.fromJson(response);
  }

  @override
  Future<List<Reservation>> list({String? accessToken}) async {
    final response = await _apiClient.getJson(
      '/api/v1/reservations',
      accessToken: accessToken,
    );
    if (response is! List) {
      throw const FormatException('Reservation list must be a JSON array');
    }
    return response
        .map((item) => Reservation.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  @override
  Future<Reservation> get(
    String reservationId, {
    String? accessToken,
  }) async {
    final response = await _apiClient.getJson(
      '/api/v1/reservations/$reservationId',
      accessToken: accessToken,
    );
    return Reservation.fromJson(Map<String, dynamic>.from(response! as Map));
  }

  @override
  Future<Reservation> update(
    String reservationId,
    ReservationInput input, {
    String? accessToken,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/v1/reservations/$reservationId',
      requestBody: input.toJson(),
      accessToken: accessToken,
    );
    return Reservation.fromJson(response);
  }

  @override
  Future<Reservation> cancel(
    String reservationId, {
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/reservations/$reservationId/cancel',
      accessToken: accessToken,
    );
    return Reservation.fromJson(response);
  }
}
