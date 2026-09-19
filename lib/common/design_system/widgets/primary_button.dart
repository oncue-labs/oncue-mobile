import 'package:flutter/material.dart';

/// Full-width accent-gradient button, matching `.btn-primary` in
/// `design/mockups/tokens.css`. Used for the main action on a screen.
final class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: onPressed == null
              ? null
              : LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null
                ? colorScheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
            foregroundColor: colorScheme.onPrimary,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 6)],
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
