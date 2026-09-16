// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oncue_mobile/app/oncue_app.dart';

void main() {
  testWidgets('opens on the call combination selection screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OnCueApp());

    expect(find.text('통화 조합 선택'), findsOneWidget);
    expect(find.text('산타'), findsOneWidget);
  });

  testWidgets('switches between combination and reservation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OnCueApp());

    await tester.tap(find.byKey(const ValueKey('reservation-tab')));
    await tester.pumpAndSettle();

    expect(find.text('예약된 통화가 없습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('combination-tab')));
    await tester.pumpAndSettle();

    expect(find.text('통화 조합 선택'), findsOneWidget);
    expect(find.text('산타'), findsOneWidget);
  });
}
