import 'package:oncue_mobile/call/model/connection_token.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

final class CallConnectionApiClient implements CallConnectionTokenIssuer {
  CallConnectionApiClient(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ConnectionToken> issueConnectionToken(
    String callSessionId, {
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/call-sessions/$callSessionId/connection-token',
      accessToken: accessToken,
    );
    return ConnectionToken.fromJson(response);
  }
}
