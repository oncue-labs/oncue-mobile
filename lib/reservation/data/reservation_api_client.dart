import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class ReservationApiClient {
  ReservationApiClient(this._apiClient);

  final ApiClient _apiClient;

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
