import 'package:flutter/material.dart';

/// The single page-title type scale used everywhere a screen names
/// itself at the top — top-level tab headers, drill-down app bars and
/// body-level persona headings alike, so every page title looks the
/// same regardless of where it sits.
TextStyle pageTitleStyle(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
    fontSize: 22.7,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.68,
  );
}
