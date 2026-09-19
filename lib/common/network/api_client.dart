abstract interface class ApiClient {
  Future<Object?> getJson(String requestPath, {String? accessToken});

  Future<Map<String, dynamic>> postJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  });

  Future<Map<String, dynamic>> patchJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  });

  Future<Map<String, dynamic>> putJson(
    String requestPath, {
    Map<String, dynamic>? requestBody,
    String? accessToken,
  });

  Future<Object?> deleteJson(String requestPath, {String? accessToken});
}
