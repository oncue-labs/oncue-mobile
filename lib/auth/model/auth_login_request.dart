final class AuthLoginRequest {
  const AuthLoginRequest.kakao({required this.providerAccessToken})
    : provider = 'kakao',
      authorizationCode = null,
      codeVerifier = null;

  const AuthLoginRequest.x({
    required this.authorizationCode,
    required this.codeVerifier,
  }) : provider = 'x',
       providerAccessToken = null;

  final String provider;

  // Kakao 네이티브 SDK가 발급한 단기 provider access token.
  final String? providerAccessToken;

  // X OAuth 인증 서버가 발급한 단기 authorization code.
  final String? authorizationCode;

  // X OAuth 인증 시작 때 생성한 PKCE 검증 값.
  final String? codeVerifier;

  Map<String, dynamic> toJson() {
    if (provider == 'kakao') {
      return {'provider': provider, 'providerAccessToken': providerAccessToken};
    }

    return {
      'provider': provider,
      'authorizationCode': authorizationCode,
      'codeVerifier': codeVerifier,
    };
  }
}
