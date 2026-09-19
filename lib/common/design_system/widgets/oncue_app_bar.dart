import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// Drill-down screen header, matching `.app-bar` in
/// `design/mockups/tokens.css` — a muted back caret, a tight bold title
/// and a hairline bottom border.
final class OnCueAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OnCueAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  static const double _borderHeight = 1;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + _borderHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.extension<OnCueColors>()?.line ?? theme.colorScheme.outline;

    final titleStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );

    return AppBar(
      title: Text(title, style: titleStyle),
      actions: actions,
      titleTextStyle: titleStyle,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_borderHeight),
        child: Container(height: _borderHeight, color: line),
      ),
    );
  }
}
