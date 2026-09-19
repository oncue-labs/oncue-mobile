import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// Rounded surface container matching `.card` in
/// `design/mockups/tokens.css`.
final class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.extension<OnCueColors>()?.line ?? theme.colorScheme.outline;

    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: child,
    );
  }
}
