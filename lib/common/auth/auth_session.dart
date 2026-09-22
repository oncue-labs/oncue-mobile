final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.createdAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      refreshToken: json['refreshToken'] as String?,
      refreshTokenExpiresAt: json['refreshTokenExpiresAt'] == null
          ? null
          : DateTime.parse(json['refreshTokenExpiresAt'] as String),
    );
  }
}
