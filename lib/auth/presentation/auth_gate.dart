import 'package:flutter/material.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/auth/presentation/login_page.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';

final class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.authorizationClient,
    required this.homeBuilder,
  });

  final AuthService authService;
  final OAuthAuthorizationClient authorizationClient;
  final Widget Function(AuthSession session) homeBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

final class _AuthGateState extends State<AuthGate> {
  AuthSession? _session;
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: ValueKey('auth-loading')),
        ),
      );
    }

    if (_loadError != null) {
      return const Scaffold(body: Center(child: Text('로그인 상태를 확인하지 못했습니다.')));
    }

    final session = _session;
    if (session == null) {
      return LoginPage(onLogin: _login);
    }

    return widget.homeBuilder(session);
  }

  Future<void> _restoreSession() async {
    try {
      final session = await widget.authService.loadSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _login(AuthProvider provider) async {
    final authorization = await widget.authorizationClient.authorize(provider);
    switch (provider) {
      case AuthProvider.kakao:
        await widget.authService.loginWithKakao(
          authorizationCode: authorization.authorizationCode,
          codeVerifier: authorization.codeVerifier,
        );
      case AuthProvider.x:
        await widget.authService.loginWithX(
          authorizationCode: authorization.authorizationCode,
          codeVerifier: authorization.codeVerifier,
        );
    }

    final session = await widget.authService.loadSession();
    if (session == null) {
      throw StateError('Login completed without a saved session');
    }
    if (!mounted) {
      return;
    }
    setState(() => _session = session);
  }
}
