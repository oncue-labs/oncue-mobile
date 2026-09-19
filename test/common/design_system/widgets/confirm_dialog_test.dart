import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/confirm_dialog.dart';

void main() {
  Widget buildHarness(void Function(bool? result) onResult) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showOnCueConfirmDialog(
                context,
                title: '예약을 취소할까요?',
                message: '취소한 예약은 다시 사용할 수 없습니다.',
                confirmLabel: '예약 취소',
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('resolves true and dismisses when confirmed', (tester) async {
    bool? result;
    await tester.pumpWidget(buildHarness((value) => result = value));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('예약을 취소할까요?'), findsOneWidget);
    expect(find.text('취소한 예약은 다시 사용할 수 없습니다.'), findsOneWidget);

    await tester.tap(find.text('예약 취소'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('예약을 취소할까요?'), findsNothing);
  });

  testWidgets('resolves false when cancelled', (tester) async {
    bool? result;
    await tester.pumpWidget(buildHarness((value) => result = value));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('돌아가기'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
