import 'package:oncue_mobile/auth/model/auth_provider.dart';

final class OAuthAuthorizationResult {
  const OAuthAuthorizationResult.kakao({required this.providerAccessToken})
    : authorizationCode = null,
      codeVerifier = null;

  const OAuthAuthorizationResult.x({
    required this.authorizationCode,
    required this.codeVerifier,
  }) : providerAccessToken = null;

  // Kakao 네이티브 SDK가 발급한 단기 provider access token.
  final String? providerAccessToken;

  // 백엔드가 외부 로그인 계정과 교환할 단기 인증 코드.
  final String? authorizationCode;

  // OAuth 인증 시작 때 만든 PKCE 검증 값.
  final String? codeVerifier;
}

/// 외부 OAuth SDK가 반환한 인증 결과를 앱 내부 형태로 바꾸는 경계.
abstract interface class OAuthAuthorizationClient {
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider);
}
