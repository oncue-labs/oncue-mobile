import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/outline_button.dart';

void main() {
  testWidgets('invokes onPressed when tapped', (WidgetTester tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutlineButton(
            label: '예약 수정',
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.text('예약 수정'), findsOneWidget);

    await tester.tap(find.text('예약 수정'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('renders as disabled when onPressed is null', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OutlineButton(label: '예약 수정', onPressed: null),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });
}
