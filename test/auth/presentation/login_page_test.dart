import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/model/auth_provider.dart';
import 'package:oncue_mobile/auth/presentation/login_page.dart';

void main() {
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
