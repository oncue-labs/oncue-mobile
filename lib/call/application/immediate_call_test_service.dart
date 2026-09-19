import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';

/// Starts a local-only call directly from an existing reservation.
final class ImmediateCallTestService {
  ImmediateCallTestService(this._callSessionApi, this._callConnection);

  final CallSessionCommandApi _callSessionApi;
  final CallConnection _callConnection;

  Future<void> start(String reservationId, {String? accessToken}) async {
    final callSession = await _callSessionApi.prepareTestCall(
      reservationId,
      accessToken: accessToken,
    );
    await _callConnection.connect(
      callSession.callSessionId,
      accessToken: accessToken,
    );
  }

  Future<void> hangup() {
    return _callConnection.hangup();
  }
}
