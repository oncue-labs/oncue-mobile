import 'package:flutter/material.dart';

/// Variant of [StatusChip], matching `.status-chip.is-*` in
/// `design/mockups/tokens.css`.
enum StatusChipVariant { scheduled, cancelled }

/// Small pill label for reservation status, matching `.status-chip`.
final class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.variant});

  final String label;
  final StatusChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (variant) {
      StatusChipVariant.scheduled => colorScheme.primary,
      StatusChipVariant.cancelled => colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
