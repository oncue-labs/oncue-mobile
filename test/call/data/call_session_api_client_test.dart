import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

void main() {
  test(
    'rejects a call session using the confirmed endpoint and maps its response',
    () async {
      final apiClient = _RecordingApiClient(
        response: {
          'callSessionId': 'call-session-123',
          'callStatus': 'RINGING',
          'callOutcome': 'FAILED',
          'createdAt': '2026-09-12T10:00:00Z',
          'endedAt': '2026-09-12T10:00:05Z',
        },
      );
      final client = CallSessionApiClient(apiClient);

      final session = await client.reject('call-session-123');

      expect(apiClient.path, '/api/v1/call-sessions/call-session-123/reject');
      expect(apiClient.body, isNull);
      expect(session.callSessionId, 'call-session-123');
      expect(session.callStatus, 'RINGING');
      expect(session.callOutcome, 'FAILED');
      expect(session.endedAt, DateTime.parse('2026-09-12T10:00:05Z'));
    },
  );
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<Object?> getJson(String requestPath, {String? accessToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  }) async {
    throw UnimplementedError();
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
    path = requestPath;
    body = requestBody;
    return response;
  }
}
