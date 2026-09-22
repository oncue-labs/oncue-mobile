import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';

abstract interface class AuthClient {
  Future<AuthSession> login(AuthLoginRequest request);

  Future<AuthSession> refresh(String refreshToken);

  Future<void> revoke(String refreshToken);
}

final class AuthApiClient implements AuthClient {
  AuthApiClient(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthSession> login(AuthLoginRequest request) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/login',
      requestBody: request.toJson(),
    );
    return AuthSession.fromJson(response);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/refresh',
      requestBody: {'refreshToken': refreshToken},
    );
    return AuthSession.fromJson(response);
  }

  @override
  Future<void> revoke(String refreshToken) async {
    await _apiClient.postJson(
      '/api/v1/auth/logout',
      requestBody: {'refreshToken': refreshToken},
    );
  }
}
