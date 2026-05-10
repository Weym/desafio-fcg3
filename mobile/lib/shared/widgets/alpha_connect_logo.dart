import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Theme-adaptive Alpha Connect branding widget.
/// Renders SVG logos from assets with theme-aware color tinting.
/// Full logo (α + ALPHA CONNECT text) or short logo (α mark only).
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

  /// Override color for the logo. Defaults to `Theme.of(context).colorScheme.primary`.
  final Color? color;

  /// Whether to show the full logo (α + text). Auto-disabled when [size] <= 40.
  final bool showText;

  /// Whether to show the tagline (only relevant with full logo).
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final useFullLogo = showText && size > 40;

    final assetPath = useFullLogo
        ? 'assets/logos/alpha_connect_logo.svg'
        : 'assets/logos/alpha_connect_shortlogo.svg';

    return SvgPicture.asset(
      assetPath,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      semanticsLabel: 'Alpha Connect Logo',
    );
  }
}
