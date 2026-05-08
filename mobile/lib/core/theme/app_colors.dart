import 'package:flutter/material.dart';

/// Cyber-Academic Design System color palette.
///
/// Based on Material 3 tonal palette with cyberpunk-academic aesthetic.
/// Electric Teal primary, Cyber Violet secondary, Magenta accents, Obsidian surfaces.
/// Light and dark variants provided for full theme support.
class AppColors {
  // === Light Theme ===
  static const Color primary = Color(0xFF00E5FF);
  static const Color onPrimary = Color(0xFF000000);
  static const Color primaryContainer = Color(0xFF004D57);
  static const Color onPrimaryContainer = Color(0xFF97F0FF);

  static const Color secondary = Color(0xFF7209B7);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF3D0066);
  static const Color onSecondaryContainer = Color(0xFFE8CDFF);

  static const Color tertiary = Color(0xFFF72585);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF7A0036);
  static const Color onTertiaryContainer = Color(0xFFFFD9E3);

  static const Color error = Color(0xFFFF453A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFF930006);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color surface = Color(0xFFF5F5F7);
  static const Color onSurface = Color(0xFF111317);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F0F2);
  static const Color surfaceContainer = Color(0xFFE8E8EA);
  static const Color surfaceContainerHigh = Color(0xFFDDDDE0);
  static const Color surfaceContainerHighest = Color(0xFFD2D2D5);

  static const Color onSurfaceVariant = Color(0xFF44474F);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6D0);

  // === Dark Theme ===
  static const Color darkPrimary = Color(0xFF00E5FF);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkPrimaryContainer = Color(0xFF003740);
  static const Color darkOnPrimaryContainer = Color(0xFF97F0FF);

  static const Color darkSecondary = Color(0xFFBB86FC);
  static const Color darkOnSecondary = Color(0xFF1A0033);
  static const Color darkSecondaryContainer = Color(0xFF4A148C);
  static const Color darkOnSecondaryContainer = Color(0xFFE8CDFF);

  static const Color darkTertiary = Color(0xFFFF79A8);
  static const Color darkOnTertiary = Color(0xFF3B0019);
  static const Color darkTertiaryContainer = Color(0xFF5C0029);
  static const Color darkOnTertiaryContainer = Color(0xFFFFD9E3);

  static const Color darkError = Color(0xFFFF453A);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  static const Color darkSurface = Color(0xFF111317);
  static const Color darkOnSurface = Color(0xFFE6E6EA);
  static const Color darkSurfaceContainerLowest = Color(0xFF0D0E12);
  static const Color darkSurfaceContainerLow = Color(0xFF1A1C20);
  static const Color darkSurfaceContainer = Color(0xFF222428);
  static const Color darkSurfaceContainerHigh = Color(0xFF2C2E33);
  static const Color darkSurfaceContainerHighest = Color(0xFF37393E);

  static const Color darkOnSurfaceVariant = Color(0xFFC4C6D0);
  static const Color darkOutline = Color(0xFF8E9099);
  static const Color darkOutlineVariant = Color(0xFF44474F);

  // === Neon Glow Colors (for BoxShadow/effects — NOT part of ColorScheme) ===
  static const Color neonTeal = Color(0xFF00E5FF);
  static const Color neonViolet = Color(0xFF7209B7);
  static const Color neonMagenta = Color(0xFFF72585);
}
