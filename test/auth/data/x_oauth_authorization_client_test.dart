import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:oncue_mobile/auth/data/x_oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

void main() {
  test('sends the X PKCE request and maps its response', () async {
    AuthorizationRequest? capturedRequest;
    final client = XOAuthAuthorizationClient(
      configuration: const XOAuthConfiguration(
        clientId: 'x-client-id',
        redirectUri: 'com.oncue.oncuemobile://oauth/x/callback',
      ),
      runAuthorization: (request) async {
        capturedRequest = request;
        return const AuthorizationResponse(
          authorizationCode: 'x-authorization-code',
          codeVerifier: 'x-code-verifier',
        );
      },
    );

    final result = await client.authorize(AuthProvider.x);

    expect(result.authorizationCode, 'x-authorization-code');
    expect(result.codeVerifier, 'x-code-verifier');
    expect(capturedRequest?.clientId, 'x-client-id');
    expect(
      capturedRequest?.redirectUrl,
      'com.oncue.oncuemobile://oauth/x/callback',
    );
    expect(capturedRequest?.scopes, [
      'tweet.read',
      'users.read',
      'offline.access',
    ]);
    expect(
      capturedRequest?.serviceConfiguration?.authorizationEndpoint,
      'https://x.com/i/oauth2/authorize',
    );
    expect(
      capturedRequest?.serviceConfiguration?.tokenEndpoint,
      'https://api.x.com/2/oauth2/token',
    );
  });

  test('rejects authorization for a different provider', () async {
    final client = XOAuthAuthorizationClient(
      configuration: const XOAuthConfiguration(
        clientId: 'x-client-id',
        redirectUri: 'com.oncue.oncuemobile://oauth/x/callback',
      ),
      runAuthorization: (_) async => const AuthorizationResponse(),
    );

    expect(
      () => client.authorize(AuthProvider.kakao),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects an incomplete X authorization response', () async {
    final client = XOAuthAuthorizationClient(
      configuration: const XOAuthConfiguration(
        clientId: 'x-client-id',
        redirectUri: 'com.oncue.oncuemobile://oauth/x/callback',
      ),
      runAuthorization: (_) async => const AuthorizationResponse(
        authorizationCode: 'x-authorization-code',
      ),
    );

    expect(() => client.authorize(AuthProvider.x), throwsA(isA<StateError>()));
  });
}
