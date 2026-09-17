import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

typedef KakaoAccessTokenLoader = Future<String> Function();

/// Kakao 네이티브 SDK의 provider access token을 앱 내부 인증 결과로 변환한다.
final class KakaoOAuthAuthorizationClient implements OAuthAuthorizationClient {
  const KakaoOAuthAuthorizationClient({required this.loadAccessToken});

  final KakaoAccessTokenLoader loadAccessToken;

  @override
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider) async {
    if (provider != AuthProvider.kakao) {
      throw ArgumentError.value(
        provider,
        'provider',
        'Kakao provider required',
      );
    }

    final accessToken = await loadAccessToken();
    if (accessToken.trim().isEmpty) {
      throw StateError('Kakao provider access token is empty');
    }
    return OAuthAuthorizationResult.kakao(providerAccessToken: accessToken);
  }
}
