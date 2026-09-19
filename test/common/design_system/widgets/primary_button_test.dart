import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/primary_button.dart';

void main() {
  testWidgets('invokes onPressed when tapped', (WidgetTester tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: '예약하기',
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.text('예약하기'), findsOneWidget);

    await tester.tap(find.text('예약하기'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('renders as disabled when onPressed is null', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: '예약하기', onPressed: null),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
