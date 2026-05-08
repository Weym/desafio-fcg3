import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme-adaptive Alpha Connect full branding widget.
/// Renders the stylized α mark + "ALPHA CONNECT" text using fonts.
/// No JPEG dependency — adapts to light/dark theme automatically.
class AlphaConnectLogo extends StatelessWidget {
  const AlphaConnectLogo({
    super.key,
    required this.size,
    this.color,
    this.showText = true,
    this.showTagline = false,
  });

  /// Height of the α mark portion. Total widget height is larger when text is shown.
  final double size;

  /// Override color for the logo. Defaults to `Theme.of(context).colorScheme.primary`.
  final Color? color;

  /// Whether to show "ALPHA" + "CONNECT" text below the mark.
  /// Automatically disabled when [size] <= 40.
  final bool showText;

  /// Whether to show the tagline below the text (splash screen).
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveShowText = showText && size > 40;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The α mark — using Playfair Display Black for the Greek alpha character.
        // This produces the thick serif α with large bowl, elongated counter, and X-tail
        // matching the reference branding.
        Text(
          'α',
          style: GoogleFonts.playfairDisplay(
            fontSize: size * 1.2,
            fontWeight: FontWeight.w900,
            height: 1.0,
            color: effectiveColor,
          ),
        ),
        if (effectiveShowText) ...[
          SizedBox(height: size * 0.08),
          // "ALPHA" text — geometric sans-serif with flat-top A's
          Text(
            'ALPHA',
            style: GoogleFonts.orbitron(
              fontSize: size * 0.24,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.03,
              color: effectiveColor,
            ),
          ),
          SizedBox(height: size * 0.02),
          // "CONNECT" text — same geometric font, lighter weight
          Text(
            'CONNECT',
            style: GoogleFonts.orbitron(
              fontSize: size * 0.16,
              fontWeight: FontWeight.w400,
              letterSpacing: size * 0.05,
              color: effectiveColor,
            ),
          ),
          if (showTagline) ...[
            SizedBox(height: size * 0.08),
            Text(
              'INTEGRAÇÃO QUE CONECTA. INFORMAÇÃO QUE TRANSFORMA.',
              style: GoogleFonts.orbitron(
                fontSize: size * 0.06,
                fontWeight: FontWeight.w300,
                letterSpacing: size * 0.01,
                color: effectiveColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }
}
