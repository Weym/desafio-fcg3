import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Theme-adaptive Alpha Connect branding widget.
///
/// Renders brightness-specific SVG logo variants:
/// - Light mode: dark fills (#111317) on light backgrounds
/// - Dark mode: light fills (#E6E6EA) on dark backgrounds
///
/// Full logo (α + ALPHA CONNECT text) when [showText] is true and [size] > 40.
/// Short logo (α mark only) otherwise.
///
/// When [color] is provided, applies a single-color tint via [ColorFilter.mode]
/// (override mode). When [color] is null (default), the SVG renders with its
/// baked-in fill colors — no color filter applied.
class AlphaConnectLogo extends StatelessWidget {
  const AlphaConnectLogo({
    super.key,
    required this.size,
    this.color,
    this.showText = true,
    this.showTagline = false,
  });

  /// Height of the logo widget.
  final double size;

  /// Override color for the logo. When non-null, applies [ColorFilter.mode]
  /// with [BlendMode.srcIn] to tint the entire SVG to this single color.
  /// When null (default), the SVG renders with its brightness-appropriate
  /// baked-in fill colors.
  final Color? color;

  /// Whether to show the full logo (α + text). Auto-disabled when [size] <= 40.
  final bool showText;

  /// Whether to show the tagline (only relevant with full logo).
  /// Currently the full logo SVG already contains the tagline text.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useFullLogo = showText && size > 40;

    String assetPath;
    if (useFullLogo) {
      assetPath = isDark
          ? 'assets/logos/alpha_connect_logo_dark.svg'
          : 'assets/logos/alpha_connect_logo_light.svg';
    } else {
      assetPath = isDark
          ? 'assets/logos/alpha_connect_shortlogo_dark.svg'
          : 'assets/logos/alpha_connect_shortlogo_light.svg';
    }

    return SvgPicture.asset(
      assetPath,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      semanticsLabel: 'Alpha Connect Logo',
    );
  }
}
