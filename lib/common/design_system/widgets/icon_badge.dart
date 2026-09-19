import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// Variant of [IconBadge], matching `.icon-badge.is-*` in
/// `design/mockups/tokens.css`.
enum IconBadgeVariant { accent, muted, danger }

/// Rounded icon tile used ahead of list rows and detail sections, matching
/// `.icon-badge`.
final class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.variant});

  final IconData icon;
  final IconBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStrong = theme.extension<OnCueColors>()?.mutedStrong ??
        theme.colorScheme.onSurfaceVariant;
    final color = switch (variant) {
      IconBadgeVariant.accent => theme.colorScheme.primary,
      IconBadgeVariant.muted => mutedStrong,
      IconBadgeVariant.danger => theme.colorScheme.error,
    };

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}
