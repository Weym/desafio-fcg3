import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A glassmorphism-style card matching the Cyber-Academic design system.
///
/// Features a frosted-glass background with 20px backdrop blur, 5% white fill,
/// 12% white border, and neon outer glow. Adapts to light/dark mode.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.glowColor,
    this.elevation = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  /// Custom glow color. Defaults to neonTeal in dark mode, primary in light.
  final Color? glowColor;

  /// Glow intensity level: 1 (subtle), 2 (medium), 3 (hero).
  final int elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);

    // Glow alpha based on elevation level
    final double glowAlpha;
    switch (elevation) {
      case 2:
        glowAlpha = 0.25;
      case 3:
        glowAlpha = 0.35;
      default:
        glowAlpha = 0.15;
    }

    final effectiveGlowColor = glowColor ??
        (isDark ? AppColors.neonTeal : AppColors.primary);

    final card = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withValues(alpha: isDark ? glowAlpha : glowAlpha * 0.5),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
