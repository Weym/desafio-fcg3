import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Navigation item data class for [GlassBottomNav].
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Glass-panel bottom navigation with Cyber-Academic neon glow accent.
///
/// Extracted from client_shell.dart and staff_shell.dart to eliminate
/// duplication. Both shells now import this single shared widget.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> destinations;
  final ValueChanged<int> onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.neonTeal.withValues(alpha: 0.15)
                    : colors.outline.withValues(alpha: 0.1),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.neonTeal.withValues(alpha: 0.08)
                    : colors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : AppAnimations.navTransitionDuration,
                  curve: AppAnimations.navTransitionCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonTeal.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.neonTeal.withValues(alpha: 0.35),
                              blurRadius: AppAnimations.navGlowBlurSelected,
                              spreadRadius: AppAnimations.navGlowSpreadSelected,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: AppAnimations.navIconSizeDefault,
                          end: isSelected ? AppAnimations.navIconSizeSelected : AppAnimations.navIconSizeDefault,
                        ),
                        duration: reduceMotion ? Duration.zero : AppAnimations.navTransitionDuration,
                        curve: AppAnimations.navTransitionCurve,
                        builder: (context, size, child) {
                          return Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: size,
                            color: isSelected
                                ? AppColors.neonTeal
                                : colors.onSurfaceVariant,
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isSelected
                              ? AppColors.neonTeal
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
