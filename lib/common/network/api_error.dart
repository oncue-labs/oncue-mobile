final class ApiError implements Exception {
  const ApiError({
    required this.statusCode,
    required this.message,
    this.code,
    this.requestId,
    this.createdAt,
  });

  final int statusCode;
  final String message;
  final String? code;
  final String? requestId;
  final DateTime? createdAt;

  factory ApiError.fromJson(
    int statusCode,
    Map<String, dynamic> json,
  ) {
    final createdAtValue = json['createdAt'];
    return ApiError(
      statusCode: statusCode,
      message: json['message'] as String? ?? '요청을 처리하지 못했습니다.',
      code: json['code'] as String?,
      requestId: json['requestId'] as String?,
      createdAt: createdAtValue == null
          ? null
          : DateTime.parse(createdAtValue as String),
    );
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}
