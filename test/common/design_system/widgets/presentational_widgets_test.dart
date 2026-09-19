import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_avatar.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_card.dart';
import 'package:oncue_mobile/common/design_system/widgets/empty_state.dart';
import 'package:oncue_mobile/common/design_system/widgets/header_banner.dart';
import 'package:oncue_mobile/common/design_system/widgets/icon_badge.dart';
import 'package:oncue_mobile/common/design_system/widgets/status_chip.dart';

Widget _harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AppCard renders its child', (tester) async {
    await tester.pumpWidget(
      _harness(const AppCard(child: Text('카드 내용'))),
    );

    expect(find.text('카드 내용'), findsOneWidget);
  });

  testWidgets('StatusChip shows the scheduled label', (tester) async {
    await tester.pumpWidget(
      _harness(
        const StatusChip(label: '예약됨', variant: StatusChipVariant.scheduled),
      ),
    );

    expect(find.text('예약됨'), findsOneWidget);
  });

  testWidgets('StatusChip shows the cancelled label', (tester) async {
    await tester.pumpWidget(
      _harness(
        const StatusChip(label: '취소됨', variant: StatusChipVariant.cancelled),
      ),
    );

    expect(find.text('취소됨'), findsOneWidget);
  });

  testWidgets('IconBadge renders the given icon', (tester) async {
    await tester.pumpWidget(
      _harness(
        const IconBadge(icon: Icons.phone, variant: IconBadgeVariant.accent),
      ),
    );

    expect(find.byIcon(Icons.phone), findsOneWidget);
  });

  testWidgets('AppAvatar falls back to the given child when no image is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const AppAvatar(fallback: Icon(Icons.person))),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('AppAvatar falls back to the given child when the image fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const AppAvatar(
          image: AssetImage('assets/images/does-not-exist.png'),
          fallback: Icon(Icons.person),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('HeaderBanner renders eyebrow, title and subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const HeaderBanner(
          eyebrow: 'ONCUE',
          title: '통화 조합',
          subtitle: '페르소나를 골라보세요',
        ),
      ),
    );

    expect(find.text('ONCUE'), findsOneWidget);
    expect(find.text('통화 조합'), findsOneWidget);
    expect(find.text('페르소나를 골라보세요'), findsOneWidget);
  });

  testWidgets('EmptyState renders its icon and message', (tester) async {
    await tester.pumpWidget(
      _harness(
        const EmptyState(icon: Icons.inbox, message: '아직 공개된 페르소나가 없어요'),
      ),
    );

    expect(find.byIcon(Icons.inbox), findsOneWidget);
    expect(find.text('아직 공개된 페르소나가 없어요'), findsOneWidget);
  });

  testWidgets('HeaderBanner omits the eyebrow row when none is given', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(const HeaderBanner(title: '전화 예약')));

    expect(find.text('전화 예약'), findsOneWidget);
  });

  testWidgets('HeaderBanner keeps its title clear of the top system UI', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(const HeaderBanner(title: '전화 예약')));

    expect(
      find.descendant(
        of: find.byType(HeaderBanner),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
  });

  testWidgets('EmptyState renders an optional description below the message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const EmptyState(
          icon: Icons.inbox,
          message: '아직 공개된 페르소나가 없어요',
          description: '새로운 조합이 열리면 가장 먼저 알려드릴게요.',
        ),
      ),
    );

    expect(find.text('새로운 조합이 열리면 가장 먼저 알려드릴게요.'), findsOneWidget);
  });
}
