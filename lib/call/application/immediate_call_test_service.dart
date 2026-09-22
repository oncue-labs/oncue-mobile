import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/common/network/api_error.dart';

/// Starts a local-only call directly from an existing reservation.
final class ImmediateCallTestService {
  ImmediateCallTestService(
    this._callSessionApi,
    this._callConnection, {
    CallDiagnosticLogger? diagnosticLogger,
  }) : _diagnosticLogger = diagnosticLogger ?? logCallDiagnostic;

  final CallSessionCommandApi _callSessionApi;
  final CallConnection _callConnection;
  final CallDiagnosticLogger _diagnosticLogger;

  Future<void> start(String reservationId, {String? accessToken}) async {
    _diagnosticLogger(
      'immediate_call.prepare_start reservationId=$reservationId',
    );
    try {
      final callSession = await _callSessionApi.prepareTestCall(
        reservationId,
        accessToken: accessToken,
      );
      _diagnosticLogger(
        'immediate_call.prepare_succeeded reservationId=$reservationId '
        'callSessionId=${callSession.callSessionId}',
      );
      _diagnosticLogger(
        'immediate_call.connect_start callSessionId=${callSession.callSessionId}',
      );
      await _callConnection.connect(
        callSession.callSessionId,
        accessToken: accessToken,
      );
      _diagnosticLogger(
        'immediate_call.connect_succeeded callSessionId=${callSession.callSessionId}',
      );
    } catch (error) {
      _diagnosticLogger('immediate_call.failed errorType=${error.runtimeType}');
      rethrow;
    }
  }

  /// Requests the same APNs and CallKit path used by a scheduled call.
  Future<void> ringIncomingCall(
    String reservationId, {
    String? accessToken,
  }) async {
    _diagnosticLogger(
      'immediate_incoming_call.request_start reservationId=$reservationId',
    );
    try {
      final callSession = await _callSessionApi.ringTestIncomingCall(
        reservationId,
        accessToken: accessToken,
      );
      _diagnosticLogger(
        'immediate_incoming_call.request_succeeded reservationId=$reservationId '
        'callSessionId=${callSession.callSessionId}',
      );
    } on ApiError catch (error) {
      _diagnosticLogger(
        'immediate_incoming_call.request_failed statusCode=${error.statusCode}',
      );
      rethrow;
    } catch (error) {
      _diagnosticLogger(
        'immediate_incoming_call.request_failed errorType=${error.runtimeType}',
      );
      rethrow;
    }
  }

  Future<void> hangup() {
    return _callConnection.hangup();
  }
}
