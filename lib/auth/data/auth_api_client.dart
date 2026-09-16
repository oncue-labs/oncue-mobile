import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/network/api_client.dart';
import 'package:oncue_mobile/auth/model/auth_login_request.dart';

abstract interface class AuthClient {
  Future<AuthSession> login(AuthLoginRequest request);
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
}
