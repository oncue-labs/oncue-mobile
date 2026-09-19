import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/widgets/icon_badge.dart';

/// Centered empty/placeholder content, matching `.empty-state` in
/// `design/mockups/tokens.css` — an [IconBadge] above a bold message and
/// an optional muted description.
final class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.variant = IconBadgeVariant.accent,
  });

  final IconData icon;
  final String message;
  final String? description;
  final IconBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: icon, variant: variant),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
