import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

final class OAuthAuthorizationRouter implements OAuthAuthorizationClient {
  const OAuthAuthorizationRouter({required this.kakao, required this.x});

  final OAuthAuthorizationClient kakao;
  final OAuthAuthorizationClient x;

  @override
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider) {
    return switch (provider) {
      AuthProvider.kakao => kakao.authorize(provider),
      AuthProvider.x => x.authorize(provider),
    };
  }
}
