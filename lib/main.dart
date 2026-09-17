import 'package:flutter/material.dart';
import 'package:oncue_mobile/app/oncue_app.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/auth_api_client.dart';
import 'package:oncue_mobile/auth/data/kakao_oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_router.dart';
import 'package:oncue_mobile/auth/data/secure_auth_session_store.dart';
import 'package:oncue_mobile/auth/data/x_oauth_authorization_client.dart';
import 'package:oncue_mobile/common/config/app_config.dart';
import 'package:oncue_mobile/common/network/http_api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  if (!config.isReady) {
    runApp(const _ConfigurationRequiredApp());
    return;
  }

  await KakaoSdk.init(
    nativeAppKey: config.kakaoNativeAppKey,
    customScheme: config.kakaoCustomScheme,
  );

  final apiClient = HttpApiClient(baseUri: config.apiBaseUri);
  final authService = AuthService(
    AuthApiClient(apiClient),
    SecureAuthSessionStore(FlutterAuthSecureStorage()),
  );
  final authorizationClient = OAuthAuthorizationRouter(
    kakao: KakaoOAuthAuthorizationClient(
      loadAccessToken: () async {
        final token = await UserApi.instance.loginWithKakaoAccount();
        return token.accessToken;
      },
    ),
    x: XOAuthAuthorizationClient.fromAppAuth(
      configuration: XOAuthConfiguration(
        clientId: config.xClientId,
        redirectUri: config.xRedirectUri,
      ),
      appAuth: FlutterAppAuth(),
    ),
  );

  runApp(
    OnCueApp(
      authService: authService,
      authorizationClient: authorizationClient,
    ),
  );
}

final class _ConfigurationRequiredApp extends StatelessWidget {
  const _ConfigurationRequiredApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '앱 실행 설정이 없습니다.\n'
              'ONCUE_API_BASE_URL, ONCUE_KAKAO_NATIVE_APP_KEY, '
              'ONCUE_X_CLIENT_ID를 주입해 실행해주세요.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/*
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/
