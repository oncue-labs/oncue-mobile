import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// Persona / user avatar, matching `.avatar` in
/// `design/mockups/tokens.css`. Shows [image] when provided, otherwise
/// [fallback] (e.g. a placeholder icon).
final class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.image,
    this.fallback,
    this.isRound = false,
    this.size = 60,
  });

  final ImageProvider? image;
  final Widget? fallback;
  final bool isRound;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.extension<OnCueColors>()?.line ?? theme.colorScheme.outline;
    final borderRadius = isRound
        ? BorderRadius.circular(size)
        : BorderRadius.circular(16);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.extension<OnCueColors>()?.surfaceLight,
        borderRadius: borderRadius,
        border: Border.all(color: line),
        image: image != null
            ? DecorationImage(image: image!, fit: BoxFit.cover)
            : null,
      ),
      child: image == null ? fallback : null,
    );
  }
}
