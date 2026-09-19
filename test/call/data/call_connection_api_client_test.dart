import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/data/call_connection_api_client.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

void main() {
  test('issues a connection token using the confirmed endpoint', () async {
    final apiClient = _RecordingApiClient(
      response: {
        'connectionToken': 'signed-connection-token',
        'signalingUrl': 'ws://192.168.200.109:8000/v1/signaling/call-sessions/321',
        'iceServers': [
          {
            'urls': ['turn:192.168.200.109:3478?transport=udp'],
            'username': 'turn-user',
            'credential': 'turn-credential',
          },
        ],
        'expiresAt': '2026-09-19T12:01:00Z',
        'createdAt': '2026-09-19T12:00:00Z',
      },
    );
    final client = CallConnectionApiClient(apiClient);

    final token = await client.issueConnectionToken(
      '321',
      accessToken: 'access-token',
    );

    expect(apiClient.path, '/api/v1/call-sessions/321/connection-token');
    expect(apiClient.body, isNull);
    expect(apiClient.accessToken, 'access-token');
    expect(token.connectionToken, 'signed-connection-token');
    expect(token.signalingUrl, contains('/call-sessions/321'));
    expect(token.iceServers.single.urls.single, contains('turn:'));
    expect(token.expiresAt, DateTime.parse('2026-09-19T12:01:00Z'));
  });
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;
  Map<String, dynamic>? body;
  String? accessToken;

  @override
  Future<Object?> getJson(String requestPath, {String? accessToken}) async {
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
    this.accessToken = accessToken;
    return response;
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
}
