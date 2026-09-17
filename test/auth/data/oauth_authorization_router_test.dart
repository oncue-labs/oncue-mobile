import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_router.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

void main() {
  test('routes each provider to its own authorization client', () async {
    final kakao = _FakeAuthorizationClient(
      result: const OAuthAuthorizationResult.kakao(
        providerAccessToken: 'kakao-token',
      ),
    );
    final x = _FakeAuthorizationClient(
      result: const OAuthAuthorizationResult.x(
        authorizationCode: 'x-code',
        codeVerifier: 'x-verifier',
      ),
    );
    final router = OAuthAuthorizationRouter(kakao: kakao, x: x);

    final kakaoResult = await router.authorize(AuthProvider.kakao);
    final xResult = await router.authorize(AuthProvider.x);

    expect(kakaoResult.providerAccessToken, 'kakao-token');
    expect(xResult.authorizationCode, 'x-code');
    expect(kakao.providers, [AuthProvider.kakao]);
    expect(x.providers, [AuthProvider.x]);
  });
}

final class _FakeAuthorizationClient implements OAuthAuthorizationClient {
  _FakeAuthorizationClient({required this.result});

  final OAuthAuthorizationResult result;
  final providers = <AuthProvider>[];

  @override
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider) async {
    providers.add(provider);
    return result;
  }
}
