import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';
import 'package:oncue_mobile/common/design_system/oncue_theme.dart';

void main() {
  test('builds a dark-only theme matching the mockup token palette', () {
    final theme = buildOnCueTheme();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF11131A));
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, const Color(0xFF1B1E29));
    expect(theme.colorScheme.onSurface, const Color(0xFFF7F4ED));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFFA8ADBB));
    expect(theme.colorScheme.primary, const Color(0xFFFFB86B));
    expect(theme.colorScheme.onPrimary, const Color(0xFF281718));
    expect(theme.colorScheme.error, const Color(0xFFFF8A80));
  });

  test('exposes the tokens with no standard ColorScheme slot as an extension', () {
    final theme = buildOnCueTheme();
    final colors = theme.extension<OnCueColors>();

    expect(colors, isNotNull);
    expect(colors!.surfaceLight, const Color(0xFF252A39));
    expect(colors.surfaceRaised, const Color(0xFF2C3243));
    expect(colors.mutedStrong, const Color(0xFF7D8296));
    expect(colors.success, const Color(0xFF8FD9A8));
    expect(colors.line, const Color(0x1AFFFFFF));
    expect(colors.lineStrong, const Color(0x2EFFFFFF));
  });

  test('styles pushed-screen app bars flush against the scaffold background', () {
    final theme = buildOnCueTheme();

    expect(theme.appBarTheme.backgroundColor, const Color(0xFF11131A));
    expect(theme.appBarTheme.foregroundColor, const Color(0xFFF7F4ED));
    expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
  });
}
