import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

/// One entry of [OnCueBottomTabBar].
final class OnCueTabItem {
  const OnCueTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Frosted-glass pill tab bar anchored to the bottom of the home shell,
/// matching `.tab-bar` in `design/mockups/tokens.css`.
final class OnCueBottomTabBar extends StatelessWidget {
  const OnCueBottomTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<OnCueTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineStrong = theme.extension<OnCueColors>()?.lineStrong;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.extension<OnCueColors>()?.surfaceLight.withValues(
              alpha: 0.55,
            ),
            borderRadius: BorderRadius.circular(26),
            border: lineStrong != null ? Border.all(color: lineStrong) : null,
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _TabButton(
                    item: items[index],
                    isActive: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final OnCueTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor =
        Theme.of(context).extension<OnCueColors>()?.mutedStrong ??
        colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: isActive ? activeColor : inactiveColor),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
