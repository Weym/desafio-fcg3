import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme-adaptive Alpha Connect full branding widget.
/// Renders the stylized α mark + "ALPHA CONNECT" text programmatically.
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
        // The α mark drawn as CustomPaint
        CustomPaint(
          size: Size(size, size),
          painter: _AlphaMarkPainter(color: effectiveColor),
        ),
        if (effectiveShowText) ...[
          SizedBox(height: size * 0.12),
          // "ALPHA" text — geometric, wide tracking, semi-bold
          Text(
            'ALPHA',
            style: GoogleFonts.montserrat(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.04,
              color: effectiveColor,
            ),
          ),
          SizedBox(height: size * 0.02),
          // "CONNECT" text — lighter weight, wider tracking
          Text(
            'CONNECT',
            style: GoogleFonts.montserrat(
              fontSize: size * 0.15,
              fontWeight: FontWeight.w400,
              letterSpacing: size * 0.06,
              color: effectiveColor,
            ),
          ),
          if (showTagline) ...[
            SizedBox(height: size * 0.08),
            Text(
              'INTEGRAÇÃO QUE CONECTA. INFORMAÇÃO QUE TRANSFORMA.',
              style: GoogleFonts.montserrat(
                fontSize: size * 0.07,
                fontWeight: FontWeight.w300,
                letterSpacing: size * 0.02,
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

/// CustomPainter that draws the stylized α (alpha) mark as a filled vector path.
///
/// The mark consists of a thick "C" body with an internal counter (eye/hole)
/// and a descending "x" tail on the right side — matching the Alpha Connect branding.
class _AlphaMarkPainter extends CustomPainter {
  _AlphaMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill; // FILLED, not stroke — matching the branding

    final w = size.width;
    final h = size.height;

    // Draw the α (alpha) symbol — a FILLED shape:
    // - Large "C" shape with internal counter (eye/hole)
    // - Right side extends into a descending "x" tail
    // The mark is solid/filled, thick, with a distinctive eye in the center.

    // Outer path of the α body (the thick "C" with tail)
    final outerPath = Path();

    // Start from top-right of the mark, sweep counter-clockwise
    outerPath.moveTo(w * 0.72, h * 0.08);

    // Top curve going left
    outerPath.cubicTo(
      w * 0.50, h * 0.0,
      w * 0.22, h * 0.05,
      w * 0.12, h * 0.25,
    );

    // Left side going down
    outerPath.cubicTo(
      w * 0.02, h * 0.45,
      w * 0.02, h * 0.60,
      w * 0.12, h * 0.78,
    );

    // Bottom curve going right
    outerPath.cubicTo(
      w * 0.22, h * 0.95,
      w * 0.48, h * 0.98,
      w * 0.65, h * 0.85,
    );

    // Inner right — where it narrows before the tail
    outerPath.cubicTo(
      w * 0.72, h * 0.78,
      w * 0.70, h * 0.65,
      w * 0.62, h * 0.55,
    );

    // The tail going down-right (the "x" extension)
    outerPath.cubicTo(
      w * 0.72, h * 0.62,
      w * 0.82, h * 0.72,
      w * 0.92, h * 0.88,
    );

    // Tail tip
    outerPath.cubicTo(
      w * 0.96, h * 0.94,
      w * 0.98, h * 0.98,
      w * 0.95, h * 1.0,
    );

    // Return stroke of tail (inner edge)
    outerPath.cubicTo(
      w * 0.88, h * 0.95,
      w * 0.80, h * 0.82,
      w * 0.72, h * 0.72,
    );

    // Inner right going back up
    outerPath.cubicTo(
      w * 0.78, h * 0.55,
      w * 0.82, h * 0.35,
      w * 0.78, h * 0.20,
    );

    // Close back to start
    outerPath.cubicTo(
      w * 0.76, h * 0.12,
      w * 0.74, h * 0.10,
      w * 0.72, h * 0.08,
    );

    outerPath.close();

    // Inner counter (the "eye" hole in the α)
    // This creates the negative space in the middle
    final innerPath = Path();
    innerPath.moveTo(w * 0.45, h * 0.30);
    innerPath.cubicTo(
      w * 0.35, h * 0.32,
      w * 0.28, h * 0.42,
      w * 0.28, h * 0.52,
    );
    innerPath.cubicTo(
      w * 0.28, h * 0.62,
      w * 0.35, h * 0.72,
      w * 0.45, h * 0.74,
    );
    innerPath.cubicTo(
      w * 0.55, h * 0.72,
      w * 0.60, h * 0.62,
      w * 0.60, h * 0.52,
    );
    innerPath.cubicTo(
      w * 0.60, h * 0.42,
      w * 0.55, h * 0.32,
      w * 0.45, h * 0.30,
    );
    innerPath.close();

    // Combine: outer minus inner (creates the eye hole)
    final combinedPath =
        Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _AlphaMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
