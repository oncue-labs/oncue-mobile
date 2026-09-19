import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/auth/presentation/login_page.dart';

void main() {
  testWidgets('shows the OnCue brand block and provider buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onLogin: (_) async {})),
    );

    expect(find.text('OnCue'), findsOneWidget);
    expect(find.text('원하는 순간에 걸려올 전화를 만들어보세요.'), findsOneWidget);
    expect(find.text('카카오로 로그인'), findsOneWidget);
    expect(find.text('X로 로그인'), findsOneWidget);
  });

  testWidgets('shows an inline error message when login fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onLogin: (_) async {
            throw StateError('boom');
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('login-kakao-button')));
    await tester.pumpAndSettle();

    expect(find.text('로그인에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
  });

  testWidgets('starts Kakao login from the Kakao button', (
    WidgetTester tester,
  ) async {
    AuthProvider? selectedProvider;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onLogin: (provider) async {
            selectedProvider = provider;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('login-kakao-button')));
    await tester.pumpAndSettle();

    expect(selectedProvider, AuthProvider.kakao);
  });

  testWidgets('starts X login from the X button', (WidgetTester tester) async {
    AuthProvider? selectedProvider;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onLogin: (provider) async {
            selectedProvider = provider;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('login-x-button')));
    await tester.pumpAndSettle();

    expect(selectedProvider, AuthProvider.x);
  });
}
