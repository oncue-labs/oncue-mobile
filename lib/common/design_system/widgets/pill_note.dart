import 'package:flutter/material.dart';

/// Small accent-bordered caption, matching `.pill-note` in
/// `design/mockups/tokens.css` — used for soft disclaimers like
/// "예약 시각은 정확히 보장되지 않을 수 있어요."
final class PillNote extends StatelessWidget {
  const PillNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
