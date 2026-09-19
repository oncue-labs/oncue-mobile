import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/widgets/primary_button.dart';

/// Confirmation modal for destructive or hard-to-undo actions, matching
/// `.dialog-box` in `design/mockups/design-system.html`.
///
/// Returns `true` if the user confirmed, `false` if they cancelled or
/// dismissed the dialog.
Future<bool> showOnCueConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = '돌아가기',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(dialogContext).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: PrimaryButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
