final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.createdAt,
  });

  final String accessToken;
  final DateTime expiresAt;
  final DateTime createdAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
