import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/oncue_theme.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_app_bar.dart';

void main() {
  Widget harnessWithBackStack(Widget appBar) {
    return MaterialApp(
      theme: buildOnCueTheme(),
      home: Navigator(
        onGenerateInitialRoutes: (navigator, initialRoute) => [
          MaterialPageRoute(builder: (_) => const Scaffold()),
          MaterialPageRoute(builder: (_) => Scaffold(appBar: appBar as PreferredSizeWidget)),
        ],
      ),
    );
  }

  testWidgets('shows a back button when there is a previous route to pop to', (
    tester,
  ) async {
    await tester.pumpWidget(harnessWithBackStack(const OnCueAppBar(title: '예약 상세')));

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('예약 상세'), findsOneWidget);
  });

  testWidgets('renders the title text at the mockup size and weight', (
    tester,
  ) async {
    await tester.pumpWidget(harnessWithBackStack(const OnCueAppBar(title: '예약 상세')));

    final titleText = tester.widget<Text>(find.text('예약 상세'));
    expect(titleText.style?.fontSize, closeTo(17, 0.5));
    expect(titleText.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('draws a bottom border line under the app bar', (tester) async {
    await tester.pumpWidget(harnessWithBackStack(const OnCueAppBar(title: '예약 상세')));

    expect(
      find.descendant(
        of: find.byType(OnCueAppBar),
        matching: find.byType(PreferredSize),
      ),
      findsOneWidget,
    );
  });
}
