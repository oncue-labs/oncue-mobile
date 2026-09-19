import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_bottom_tab_bar.dart';

void main() {
  testWidgets('renders every item label and taps report the tapped index', (
    tester,
  ) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnCueBottomTabBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
            items: const [
              OnCueTabItem(icon: Icons.call, label: '통화 조합'),
              OnCueTabItem(icon: Icons.calendar_month, label: '예약 목록'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('통화 조합'), findsOneWidget);
    expect(find.text('예약 목록'), findsOneWidget);

    await tester.tap(find.text('예약 목록'));
    await tester.pump();

    expect(tappedIndex, 1);
  });
}
