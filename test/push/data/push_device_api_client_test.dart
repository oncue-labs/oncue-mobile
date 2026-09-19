import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/push/data/push_device_api_client.dart';
import 'package:oncue_mobile/push/model/push_environment.dart';

void main() {
  test('registers the current iOS token with the APNs environment', () async {
    final apiClient = _RecordingApiClient();
    final client = PushDeviceApiClient(apiClient);

    await client.register(
      deviceToken: 'device-token',
      environment: PushEnvironment.sandbox,
      accessToken: 'access-token',
    );

    expect(apiClient.method, 'PUT');
    expect(apiClient.path, '/api/v1/push-device');
    expect(apiClient.body, {
      'deviceToken': 'device-token',
      'platform': 'IOS',
      'environment': 'SANDBOX',
    });
    expect(apiClient.accessToken, 'access-token');
  });

  test('deletes the authenticated user push token on logout', () async {
    final apiClient = _RecordingApiClient();
    final client = PushDeviceApiClient(apiClient);

    await client.delete(accessToken: 'access-token');

    expect(apiClient.method, 'DELETE');
    expect(apiClient.path, '/api/v1/push-device');
    expect(apiClient.body, isNull);
    expect(apiClient.accessToken, 'access-token');
  });
}

final class _RecordingApiClient implements ApiClient {
  String? method;
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
    method = 'PUT';
    path = requestPath;
    body = requestBody;
    this.accessToken = accessToken;
    return <String, dynamic>{};
  }

  @override
  Future<Object?> deleteJson(String requestPath, {String? accessToken}) async {
    method = 'DELETE';
    path = requestPath;
    body = null;
    this.accessToken = accessToken;
    return <String, dynamic>{};
  }
}
