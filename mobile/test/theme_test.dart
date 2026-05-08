import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors', () {
    test('light primary matches Cyber-Academic Electric Teal', () {
      expect(AppColors.primary, const Color(0xFF00E5FF));
    });

    test('dark primary matches Cyber-Academic Electric Teal', () {
      expect(AppColors.darkPrimary, const Color(0xFF00E5FF));
    });

    test('light surface matches Cyber-Academic value', () {
      expect(AppColors.surface, const Color(0xFFF5F5F7));
    });

    test('dark surface matches Cyber-Academic Obsidian', () {
      expect(AppColors.darkSurface, const Color(0xFF111317));
    });

    test('error color matches Cyber-Academic value', () {
      expect(AppColors.error, const Color(0xFFFF453A));
    });

    test('secondary color is Cyber Violet', () {
      expect(AppColors.secondary, const Color(0xFF7209B7));
    });

    test('tertiary color is Magenta', () {
      expect(AppColors.tertiary, const Color(0xFFF72585));
    });

    test('neon glow colors are defined', () {
      expect(AppColors.neonTeal, const Color(0xFF00E5FF));
      expect(AppColors.neonViolet, const Color(0xFF7209B7));
      expect(AppColors.neonMagenta, const Color(0xFFF72585));
    });
  });

  group('AppSpacing', () {
    test('spacing scale has correct values', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
    });

    test('radius scale has correct values', () {
      expect(AppSpacing.radiusSm, 8);
      expect(AppSpacing.radiusMd, 12);
      expect(AppSpacing.radiusLg, 16);
      expect(AppSpacing.radiusXl, 24);
      expect(AppSpacing.radiusXxl, 32);
      expect(AppSpacing.radiusFull, 999);
    });
  });

  group('AppTheme', () {
    // Tests that access AppTheme.light/dark must use testWidgets because
    // GoogleFonts triggers async font loading that requires the binding.
    testWidgets('light theme uses Material 3', (tester) async {
      expect(AppTheme.light.useMaterial3, isTrue);
    });

    testWidgets('dark theme uses Material 3', (tester) async {
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    testWidgets('light theme has correct primary color', (tester) async {
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    });

    testWidgets('dark theme has correct primary color', (tester) async {
      expect(AppTheme.dark.colorScheme.primary, AppColors.darkPrimary);
    });

    testWidgets('light theme brightness is light', (tester) async {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    });

    testWidgets('dark theme brightness is dark', (tester) async {
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('elevated button uses pill shape (full radius)',
        (tester) async {
      final buttonShape = AppTheme.light.elevatedButtonTheme.style?.shape
          ?.resolve({});
      expect(buttonShape, isA<RoundedRectangleBorder>());
      final rrb = buttonShape as RoundedRectangleBorder;
      expect(
        rrb.borderRadius,
        BorderRadius.circular(AppSpacing.radiusFull),
      );
    });

    testWidgets('card theme has zero elevation', (tester) async {
      expect(AppTheme.light.cardTheme.elevation, 0);
    });

    testWidgets('app bar has transparent background', (tester) async {
      expect(
        AppTheme.light.appBarTheme.backgroundColor,
        Colors.transparent,
      );
    });

    test('responsiveTextTheme does not scale on phone', () {
      // Use a dummy base TextTheme (no GoogleFonts needed)
      const base = TextTheme(
        displaySmall: TextStyle(fontSize: 36),
        headlineMedium: TextStyle(fontSize: 28),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      );
      final phoneTheme = AppTheme.responsiveTextTheme(base, 400);
      expect(phoneTheme, base);
    });

    test('responsiveTextTheme scales headings on desktop', () {
      const base = TextTheme(
        displaySmall: TextStyle(fontSize: 36),
        headlineMedium: TextStyle(fontSize: 28),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      );
      final desktopTheme = AppTheme.responsiveTextTheme(base, 1200);
      expect(desktopTheme.displaySmall!.fontSize, 36 * 1.2);
      expect(desktopTheme.headlineMedium!.fontSize, 28 * 1.2);
      expect(desktopTheme.bodyLarge!.height, 1.6);
    });
  });
}
