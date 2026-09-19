import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';

const _background = Color(0xFF11131A);
const _surface = Color(0xFF1B1E29);
const _text = Color(0xFFF7F4ED);
const _muted = Color(0xFFA8ADBB);
const _accent = Color(0xFFFFB86B);
const _accentStrong = Color(0xFFFF8F5B);
const _onAccent = Color(0xFF281718);
const _danger = Color(0xFFFF8A80);
const _dangerStrong = Color(0xFFFF6B6B);

/// The single dark theme used across OnCue — the app has no light mode.
ThemeData buildOnCueTheme() {
  final colorScheme = ColorScheme.dark(
    surface: _surface,
    onSurface: _text,
    onSurfaceVariant: _muted,
    primary: _accent,
    onPrimary: _onAccent,
    secondary: _accentStrong,
    error: _danger,
    errorContainer: _dangerStrong,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _background,
    fontFamily: 'Noto Sans KR',
    extensions: const [OnCueColors.dark],
  );
}
