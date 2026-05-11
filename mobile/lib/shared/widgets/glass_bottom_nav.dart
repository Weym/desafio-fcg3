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
/// Uses an explicit [AnimationController] with [TickerProviderStateMixin] to
/// guarantee animation state persists across GoRouter navigation rebuilds.
/// The previous StatelessWidget approach (AnimatedContainer + TweenAnimationBuilder)
/// could lose animation state when GoRouter reconstructed the widget tree.
class GlassBottomNav extends StatefulWidget {
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
  State<GlassBottomNav> createState() => _GlassBottomNavState();
}

class _GlassBottomNavState extends State<GlassBottomNav>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      duration: AppAnimations.navTransitionDuration,
      vsync: this,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.navTransitionCurve,
    );
    // Start at end state so selected item shows correctly on first build
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant GlassBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // If reduced-motion is enabled, snap to final state immediately
    if (reduceMotion && _controller.value < 1.0) {
      _controller.value = 1.0;
    }

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
          child: AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(widget.destinations.length, (index) {
                  return _buildNavItem(context, index, colors);
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, ColorScheme colors) {
    final item = widget.destinations[index];
    final isSelected = index == widget.currentIndex;
    final wasPrevious = index == _previousIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _curvedAnimation.value;

    // Brightness-adaptive neon colors (per D-06)
    final glowColor = isDark ? AppColors.neonTeal : AppColors.neonTealLight;
    final selectedColor = isDark ? AppColors.neonTeal : AppColors.neonTealLight;

    // Calculate icon size with springy easeOutBack interpolation
    double iconSize;
    if (isSelected) {
      iconSize = _lerp(AppAnimations.navIconSizeDefault,
          AppAnimations.navIconSizeSelected, t);
    } else if (wasPrevious && widget.currentIndex != _previousIndex) {
      iconSize = _lerp(AppAnimations.navIconSizeSelected,
          AppAnimations.navIconSizeDefault, t);
    } else {
      iconSize = AppAnimations.navIconSizeDefault;
    }

    // Calculate glow parameters
    double glowAlpha;
    double glowBlur;
    double glowSpread;
    if (isSelected) {
      glowAlpha = _lerp(0.0, 0.35, t);
      glowBlur = _lerp(0.0, AppAnimations.navGlowBlurSelected, t);
      glowSpread = _lerp(0.0, AppAnimations.navGlowSpreadSelected, t);
    } else if (wasPrevious && widget.currentIndex != _previousIndex) {
      glowAlpha = _lerp(0.35, 0.0, t);
      glowBlur = _lerp(AppAnimations.navGlowBlurSelected, 0.0, t);
      glowSpread = _lerp(AppAnimations.navGlowSpreadSelected, 0.0, t);
    } else {
      glowAlpha = 0.0;
      glowBlur = 0.0;
      glowSpread = 0.0;
    }

    // Calculate background alpha
    double bgAlpha;
    if (isSelected) {
      bgAlpha = _lerp(0.0, 0.2, t);
    } else if (wasPrevious && widget.currentIndex != _previousIndex) {
      bgAlpha = _lerp(0.2, 0.0, t);
    } else {
      bgAlpha = 0.0;
    }

    // Icon and label color — instant switch (no lerp)
    final itemColor =
        isSelected ? selectedColor : colors.onSurfaceVariant;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgAlpha > 0.001
              ? glowColor.withValues(alpha: bgAlpha)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: glowAlpha > 0.001
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    spreadRadius: glowSpread,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: iconSize,
              color: itemColor,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Linear interpolation helper.
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
