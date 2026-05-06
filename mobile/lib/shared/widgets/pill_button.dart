import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// A pill-shaped button matching the alpha-connect prototype style.
///
/// Variants: primary (filled), secondary (container fill), ghost (outlined), error.
enum PillButtonVariant { primary, secondary, ghost, error }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PillButtonVariant.primary,
    this.isExpanded = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillButtonVariant variant;
  final bool isExpanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;
    final BorderSide? side;

    switch (variant) {
      case PillButtonVariant.primary:
        backgroundColor = colors.primary;
        foregroundColor = colors.onPrimary;
        side = null;
      case PillButtonVariant.secondary:
        backgroundColor = colors.secondaryContainer;
        foregroundColor = colors.onSecondaryContainer;
        side = null;
      case PillButtonVariant.ghost:
        backgroundColor = colors.surfaceContainer;
        foregroundColor = colors.onSurfaceVariant;
        side = BorderSide(color: colors.outlineVariant);
      case PillButtonVariant.error:
        backgroundColor = colors.error;
        foregroundColor = colors.onError;
        side = null;
    }

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: side ?? BorderSide.none,
        ),
      ),
      minimumSize: isExpanded
          ? const WidgetStatePropertyAll(Size(double.infinity, 48))
          : null,
    );

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 20),
              ],
            ],
          );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}
