import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// Bottom status toasts, matching `.snackbar` in
/// `design/mockups/design-system.html` — error / success / info variants.
final class AppSnackbar {
  const AppSnackbar._();

  static void showError(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.warning_amber, color: (
      context,
    ) =>
        Theme.of(context).colorScheme.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.check_circle, color: (
      context,
    ) =>
        Theme.of(context).extension<OnCueColors>()?.success ??
        Theme.of(context).colorScheme.primary);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.info, color: (context) =>
        Theme.of(context).colorScheme.primary);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color Function(BuildContext) color,
  }) {
    final accent = color(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).extension<OnCueColors>()?.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
