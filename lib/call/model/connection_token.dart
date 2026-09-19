final class ConnectionToken {
  const ConnectionToken({
    required this.connectionToken,
    required this.signalingUrl,
    required this.iceServers,
    required this.expiresAt,
    required this.createdAt,
  });

  final String connectionToken;
  final String signalingUrl;
  final List<IceServer> iceServers;
  final DateTime expiresAt;
  final DateTime createdAt;

  factory ConnectionToken.fromJson(Map<String, dynamic> json) {
    final iceServers = json['iceServers'] as List<dynamic>? ?? const [];
    return ConnectionToken(
      connectionToken: json['connectionToken'] as String,
      signalingUrl: json['signalingUrl'] as String,
      iceServers: List.unmodifiable(
        iceServers.map(
          (value) => IceServer.fromJson(value as Map<String, dynamic>),
        ),
      ),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

final class IceServer {
  const IceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  final List<String> urls;
  final String? username;
  final String? credential;

  factory IceServer.fromJson(Map<String, dynamic> json) {
    final urls = json['urls'] as List<dynamic>? ?? const [];
    return IceServer(
      urls: List.unmodifiable(urls.cast<String>()),
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }
}
