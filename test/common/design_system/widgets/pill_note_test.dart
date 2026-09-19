import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/pill_note.dart';

void main() {
  testWidgets('renders the given text with a left accent border', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PillNote('예약 시각은 정확히 보장되지 않을 수 있어요.')),
      ),
    );

    expect(find.text('예약 시각은 정확히 보장되지 않을 수 있어요.'), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
  });
}
