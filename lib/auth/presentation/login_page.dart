import 'package:flutter/material.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/common/design_system/widgets/kakao_symbol.dart';
import 'package:oncue_mobile/common/design_system/widgets/outline_button.dart';
import 'package:oncue_mobile/common/design_system/widgets/primary_button.dart';

const _kakaoBackground = Color(0xFFFEE500);
const _kakaoForeground = Color(0xFF191600);

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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/oncue_logo.png',
                            width: 56,
                            height: 56,
                          ),
                          const SizedBox(height: 10),
                          Text('OnCue', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            '원하는 순간에 걸려올 전화를 만들어보세요.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      PrimaryButton(
                        key: const ValueKey('login-kakao-button'),
                        label: '카카오로 로그인',
                        icon: const KakaoSymbol(color: _kakaoForeground),
                        backgroundColor: _kakaoBackground,
                        foregroundColor: _kakaoForeground,
                        onPressed: _isLoading
                            ? null
                            : () => _login(AuthProvider.kakao),
                      ),
                      const SizedBox(height: 12),
                      OutlineButton(
                        key: const ValueKey('login-x-button'),
                        label: 'X로 로그인',
                        icon: const Text(
                          '𝕏',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _login(AuthProvider.x),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              ColoredBox(
                color: theme.colorScheme.surface.withValues(alpha: 0.55),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
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
