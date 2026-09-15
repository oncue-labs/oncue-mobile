import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

abstract interface class AuthClient {
  Future<AuthSession> login(
    String provider,
    String authorizationCode,
    String codeVerifier,
  );
}

final class AuthApiClient implements AuthClient {
  AuthApiClient(this._apiClient);

  static const _supportedProviders = {'kakao', 'x'};

  final ApiClient _apiClient;

  @override
  Future<AuthSession> login(
    String provider,
    String authorizationCode,
    String codeVerifier,
  ) async {
    if (!_supportedProviders.contains(provider)) {
      throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
    }

    final response = await _apiClient.postJson(
      '/api/v1/auth/login',
      requestBody: {
        'provider': provider,
        'authorizationCode': authorizationCode,
        'codeVerifier': codeVerifier,
      },
    );
    return AuthSession.fromJson(response);
  }
}
