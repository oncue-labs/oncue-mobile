final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.kakaoNativeAppKey,
    required this.xClientId,
    this.xRedirectUri = defaultXRedirectUri,
    this.apnsEnvironment = defaultApnsEnvironment,
    this.localTestCallEnabled = false,
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
      localTestCallEnabled: bool.fromEnvironment(
        'ONCUE_LOCAL_TEST_CALL_ENABLED',
        defaultValue: false,
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

  /// Enables the local-only immediate call test action. Keep false for TestFlight.
  final bool localTestCallEnabled;

  bool get isReady =>
      apiBaseUrl.trim().isNotEmpty &&
      kakaoNativeAppKey.trim().isNotEmpty &&
      xClientId.trim().isNotEmpty &&
      xRedirectUri.trim().isNotEmpty &&
      (apnsEnvironment == 'SANDBOX' || apnsEnvironment == 'PRODUCTION');

  Uri get apiBaseUri => Uri.parse(apiBaseUrl);

  String get kakaoCustomScheme => 'kakao$kakaoNativeAppKey';
}
