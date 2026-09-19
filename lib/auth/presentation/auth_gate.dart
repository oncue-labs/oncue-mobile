import 'package:flutter/material.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/auth/presentation/login_page.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';
import 'package:oncue_mobile/common/design_system/widgets/icon_badge.dart';

final class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.authorizationClient,
    required this.homeBuilder,
  });

  final AuthService authService;
  final OAuthAuthorizationClient authorizationClient;
  final Widget Function(
    AuthSession session,
    Future<void> Function() onLogout,
  ) homeBuilder;

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
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconBadge(
                  icon: Icons.warning_amber,
                  variant: IconBadgeVariant.danger,
                ),
                const SizedBox(height: 12),
                Text(
                  '로그인 상태를 확인하지 못했습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 6),
                Text(
                  '네트워크 연결을 확인한 뒤 앱을 다시 열어주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final session = _session;
    if (session == null) {
      return LoginPage(onLogin: _login);
    }

    return widget.homeBuilder(session, _logout);
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
          providerAccessToken: authorization.providerAccessToken!,
        );
      case AuthProvider.x:
        await widget.authService.loginWithX(
          authorizationCode: authorization.authorizationCode!,
          codeVerifier: authorization.codeVerifier!,
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

  Future<void> _logout() async {
    await widget.authService.logout();
    if (!mounted) {
      return;
    }
    setState(() => _session = null);
  }
}
