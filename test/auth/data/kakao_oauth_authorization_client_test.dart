import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/data/kakao_oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

void main() {
  test('maps the Kakao provider access token', () async {
    final client = KakaoOAuthAuthorizationClient(
      loadAccessToken: () async => 'kakao-provider-access-token',
    );

    final result = await client.authorize(AuthProvider.kakao);

    expect(result.providerAccessToken, 'kakao-provider-access-token');
    expect(result.authorizationCode, isNull);
    expect(result.codeVerifier, isNull);
  });

  test('rejects authorization for a different provider', () async {
    final client = KakaoOAuthAuthorizationClient(
      loadAccessToken: () async => 'kakao-provider-access-token',
    );

    expect(
      () => client.authorize(AuthProvider.x),
      throwsA(isA<ArgumentError>()),
    );
  });
}
