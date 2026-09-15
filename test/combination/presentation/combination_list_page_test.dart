import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/combination/presentation/combination_list_page.dart';

void main() {
  testWidgets('shows the four MVP call combination cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(combinations: MvpCallCombinations.all),
      ),
    );

    expect(MvpCallCombinations.all, hasLength(4));
    expect(
      find.byKey(const ValueKey('combination-card-santa-child-roleplay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('combination-card-princess-child-roleplay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('combination-card-friend-go-home')),
      findsOneWidget,
    );
    expect(find.text('산타'), findsOneWidget);
    expect(find.text('공주'), findsOneWidget);
    expect(find.text('친구'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(
          'combination-card-travel-friend-travel-friend-introduction',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('여행 동행 친구'), findsOneWidget);
  });

  testWidgets('limits card summaries to two lines with ellipsis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(combinations: MvpCallCombinations.all),
      ),
    );

    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('summary-santa-child-roleplay')),
    );

    expect(summary.maxLines, 2);
    expect(summary.overflow, TextOverflow.ellipsis);
  });

  testWidgets('opens the selected combination detail with both input guides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CombinationListPage(combinations: MvpCallCombinations.all),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('combination-card-friend-go-home')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('detail-persona-friend')),
      findsOneWidget,
    );
    await tester.fling(find.byType(ListView), const Offset(0, -1000), 1000);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('scenario-context-input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('call-goal-input')), findsOneWidget);
    expect(find.text('10초 미리듣기'), findsOneWidget);
  });
}
