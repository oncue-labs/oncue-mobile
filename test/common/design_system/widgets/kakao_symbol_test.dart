import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/kakao_symbol.dart';

void main() {
  testWidgets('renders a CustomPaint mark without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: KakaoSymbol())),
    );

    expect(find.byType(KakaoSymbol), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(KakaoSymbol),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
