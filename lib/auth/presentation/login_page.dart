import 'package:flutter/material.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';

final class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final Future<void> Function(AuthProvider provider) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OnCue 로그인')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '로그인하고 통화 조합을 선택해보세요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('login-kakao-button'),
                  onPressed: _isLoading
                      ? null
                      : () => _login(AuthProvider.kakao),
                  child: const Text('카카오로 로그인'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const ValueKey('login-x-button'),
                  onPressed: _isLoading ? null : () => _login(AuthProvider.x),
                  child: const Text('X로 로그인'),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login(AuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onLogin(provider);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
