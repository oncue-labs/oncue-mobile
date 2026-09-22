import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

typedef XAuthorizationRunner =
    Future<AuthorizationResponse> Function(AuthorizationRequest request);

final class XOAuthConfiguration {
  const XOAuthConfiguration({
    required this.clientId,
    required this.redirectUri,
    this.authorizationEndpoint = 'https://x.com/i/oauth2/authorize',
    this.tokenEndpoint = 'https://api.x.com/2/oauth2/token',
    this.scopes = const ['tweet.read', 'users.read', 'offline.access'],
  });

  final String clientId;
  final String redirectUri;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final List<String> scopes;

  AuthorizationRequest toAuthorizationRequest() {
    return AuthorizationRequest(
      clientId,
      redirectUri,
      serviceConfiguration: AuthorizationServiceConfiguration(
        authorizationEndpoint: authorizationEndpoint,
        tokenEndpoint: tokenEndpoint,
      ),
      scopes: scopes,
    );
  }
}

/// X OAuth 2.0 Authorization Code + PKCE 결과를 앱 내부 인증 결과로 변환한다.
final class XOAuthAuthorizationClient implements OAuthAuthorizationClient {
  const XOAuthAuthorizationClient({
    required this.configuration,
    required this.runAuthorization,
  });

  factory XOAuthAuthorizationClient.fromAppAuth({
    required XOAuthConfiguration configuration,
    FlutterAppAuth? appAuth,
  }) {
    final auth = appAuth ?? FlutterAppAuth();
    return XOAuthAuthorizationClient(
      configuration: configuration,
      runAuthorization: auth.authorize,
    );
  }

  final XOAuthConfiguration configuration;
  final XAuthorizationRunner runAuthorization;

  @override
  Future<OAuthAuthorizationResult> authorize(AuthProvider provider) async {
    if (provider != AuthProvider.x) {
      throw ArgumentError.value(provider, 'provider', 'X provider required');
    }

    final response = await runAuthorization(
      configuration.toAuthorizationRequest(),
    );
    final authorizationCode = response.authorizationCode;
    final codeVerifier = response.codeVerifier;
    if (authorizationCode == null || authorizationCode.trim().isEmpty) {
      throw StateError('X authorization code is missing');
    }
    if (codeVerifier == null || codeVerifier.trim().isEmpty) {
      throw StateError('X PKCE code verifier is missing');
    }

    return OAuthAuthorizationResult.x(
      authorizationCode: authorizationCode,
      codeVerifier: codeVerifier,
    );
  }
}
