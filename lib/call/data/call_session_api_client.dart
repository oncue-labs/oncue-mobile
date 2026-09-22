import 'package:oncue_mobile/call/model/call_session.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

abstract interface class CallSessionCommandApi {
  Future<CallSession> reject(String callSessionId, {String? accessToken});

  Future<CallSession> prepareTestCall(
    String reservationId, {
    String? accessToken,
  });

  Future<CallSession> ringTestIncomingCall(
    String reservationId, {
    String? accessToken,
  });
}

final class CallSessionApiClient implements CallSessionCommandApi {
  CallSessionApiClient(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CallSession> reject(
    String callSessionId, {
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/call-sessions/$callSessionId/reject',
      accessToken: accessToken,
    );
    return CallSession.fromJson(response);
  }

  @override
  Future<CallSession> prepareTestCall(
    String reservationId, {
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/reservations/$reservationId/test-call',
      accessToken: accessToken,
    );
    return CallSession.fromJson(response);
  }

  @override
  Future<CallSession> ringTestIncomingCall(
    String reservationId, {
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/reservations/$reservationId/test-incoming-call',
      accessToken: accessToken,
    );
    return CallSession.fromJson(response);
  }
}
