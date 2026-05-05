import 'package:flutter/material.dart';
import '../responsive/breakpoints.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );

  /// Returns a [TextTheme] adapted for the given screen width.
  ///
  /// On desktop (>= 1024dp), headings scale ~20% larger and body text
  /// gets increased line height (1.6) for readability per D-24.
  static TextTheme responsiveTextTheme(TextTheme base, double screenWidth) {
    if (!AppBreakpoints.isDesktop(screenWidth)) {
      return base;
    }

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: (base.displaySmall!.fontSize ?? 36) * 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: (base.headlineMedium!.fontSize ?? 28) * 1.2,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.6,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.6,
      ),
    );
  }
}
