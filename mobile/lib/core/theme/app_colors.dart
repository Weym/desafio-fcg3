import 'package:flutter/material.dart';

/// App color palette.
///
/// WCAG AA contrast ratios verified:
/// - primary (#1565C0) on white (#FFFFFF): ~5.6:1 ✓ (min 4.5:1)
/// - error (#D32F2F) on white (#FFFFFF): ~4.6:1 ✓ (min 4.5:1)
/// - onSurface (#1C1B1F) on surface (#FAFAFA): ~15.5:1 ✓
/// - onPrimary (#FFFFFF) on primary (#1565C0): ~5.6:1 ✓
class AppColors {
  static const Color primary = Color(0xFF1565C0); // Blue 800
  static const Color primaryContainer = Color(0xFFD1E4FF);
  static const Color secondary = Color(0xFF546E7A); // Blue Grey 600
  static const Color error = Color(0xFFD32F2F);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color outline = Color(0xFF79747E);
}
