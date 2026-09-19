import 'package:flutter/material.dart';

/// Design tokens from `design/mockups/tokens.css` with no matching
/// standard [ColorScheme] slot.
final class OnCueColors extends ThemeExtension<OnCueColors> {
  const OnCueColors({
    required this.surfaceLight,
    required this.surfaceRaised,
    required this.mutedStrong,
    required this.success,
    required this.line,
    required this.lineStrong,
  });

  final Color surfaceLight;
  final Color surfaceRaised;
  final Color mutedStrong;
  final Color success;
  final Color line;
  final Color lineStrong;

  static const OnCueColors dark = OnCueColors(
    surfaceLight: Color(0xFF252A39),
    surfaceRaised: Color(0xFF2C3243),
    mutedStrong: Color(0xFF7D8296),
    success: Color(0xFF8FD9A8),
    line: Color(0x1AFFFFFF),
    lineStrong: Color(0x2EFFFFFF),
  );

  @override
  OnCueColors copyWith({
    Color? surfaceLight,
    Color? surfaceRaised,
    Color? mutedStrong,
    Color? success,
    Color? line,
    Color? lineStrong,
  }) {
    return OnCueColors(
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      mutedStrong: mutedStrong ?? this.mutedStrong,
      success: success ?? this.success,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
    );
  }

  @override
  OnCueColors lerp(ThemeExtension<OnCueColors>? other, double t) {
    if (other is! OnCueColors) {
      return this;
    }
    return OnCueColors(
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      mutedStrong: Color.lerp(mutedStrong, other.mutedStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
    );
  }
}
