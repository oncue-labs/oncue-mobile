import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_snackbar.dart';

void main() {
  Widget buildHarness(void Function(BuildContext context) onPressed) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('trigger'),
          ),
        ),
      ),
    );
  }

  testWidgets('showError displays the message with a warning icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        (context) =>
            AppSnackbar.showError(context, '예약을 취소하지 못했습니다. 다시 시도해주세요.'),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('예약을 취소하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });

  testWidgets('showSuccess displays the message with a check icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness((context) => AppSnackbar.showSuccess(context, '예약이 저장됐어요.')),
    );

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('예약이 저장됐어요.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('showInfo displays the message with an info icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        (context) => AppSnackbar.showInfo(
          context,
          '예약 시각은 정확히 보장되지 않을 수 있어요.',
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('예약 시각은 정확히 보장되지 않을 수 있어요.'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
  });
}
