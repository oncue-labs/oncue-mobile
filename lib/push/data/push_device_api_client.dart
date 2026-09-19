import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/push/model/push_environment.dart';

abstract interface class PushDeviceApiClientContract {
  Future<void> register({
    required String deviceToken,
    required PushEnvironment environment,
    required String accessToken,
  });

  Future<void> delete({required String accessToken});
}

final class PushDeviceApiClient implements PushDeviceApiClientContract {
  PushDeviceApiClient(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> register({
    required String deviceToken,
    required PushEnvironment environment,
    required String accessToken,
  }) async {
    await _apiClient.putJson(
      '/api/v1/push-device',
      requestBody: {
        'deviceToken': deviceToken,
        'platform': 'IOS',
        'environment': environment.wireValue,
      },
      accessToken: accessToken,
    );
  }

  @override
  Future<void> delete({required String accessToken}) async {
    await _apiClient.deleteJson(
      '/api/v1/push-device',
      accessToken: accessToken,
    );
  }
}
