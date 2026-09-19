import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/oncue_theme.dart';
import 'package:oncue_mobile/common/design_system/oncue_typography.dart';

void main() {
  testWidgets(
    'pageTitleStyle matches the mockup header-banner type scale everywhere',
    (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildOnCueTheme(),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final style = pageTitleStyle(capturedContext);

      expect(style.fontSize, closeTo(22.7, 0.1));
      expect(style.fontWeight, FontWeight.w800);
      expect(style.letterSpacing, closeTo(-0.68, 0.01));
    },
  );
}
