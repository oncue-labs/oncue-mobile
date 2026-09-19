final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.kakaoNativeAppKey,
    required this.xClientId,
    this.xRedirectUri = defaultXRedirectUri,
    this.apnsEnvironment = defaultApnsEnvironment,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'ONCUE_API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8080',
      ),
      kakaoNativeAppKey: String.fromEnvironment('ONCUE_KAKAO_NATIVE_APP_KEY'),
      xClientId: String.fromEnvironment('ONCUE_X_CLIENT_ID'),
      xRedirectUri: String.fromEnvironment(
        'ONCUE_X_REDIRECT_URI',
        defaultValue: defaultXRedirectUri,
      ),
      apnsEnvironment: String.fromEnvironment(
        'ONCUE_APNS_ENVIRONMENT',
        defaultValue: defaultApnsEnvironment,
      ),
    );
  }

  static const defaultXRedirectUri = 'com.oncue.oncuemobile://oauth/x/callback';
  static const defaultApnsEnvironment = 'SANDBOX';

  final String apiBaseUrl;
  final String kakaoNativeAppKey;
  final String xClientId;
  final String xRedirectUri;

  /// APNs endpoint: SANDBOX for development builds, PRODUCTION for TestFlight.
  final String apnsEnvironment;

  bool get isReady =>
      apiBaseUrl.trim().isNotEmpty &&
      kakaoNativeAppKey.trim().isNotEmpty &&
      xClientId.trim().isNotEmpty &&
      xRedirectUri.trim().isNotEmpty &&
      (apnsEnvironment == 'SANDBOX' || apnsEnvironment == 'PRODUCTION');

  Uri get apiBaseUri => Uri.parse(apiBaseUrl);

  String get kakaoCustomScheme => 'kakao$kakaoNativeAppKey';
}
