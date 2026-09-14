import 'package:oncue_mobile/call/model/call_session.dart';
import 'package:oncue_mobile/common/network/api_client.dart';

final class CallSessionApiClient {
  CallSessionApiClient(this._apiClient);

  final ApiClient _apiClient;

  Future<CallSession> reject(String callSessionId) async {
    final response = await _apiClient.postJson(
      '/api/v1/call-sessions/$callSessionId/reject',
    );
    return CallSession.fromJson(response);
  }
}
