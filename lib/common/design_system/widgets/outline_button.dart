import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// Full-width secondary action button, matching `.btn-outline` in
/// `design/mockups/tokens.css`.
final class OutlineButton extends StatelessWidget {
  const OutlineButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineStrong =
        theme.extension<OnCueColors>()?.lineStrong ?? theme.colorScheme.outline;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: lineStrong),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
