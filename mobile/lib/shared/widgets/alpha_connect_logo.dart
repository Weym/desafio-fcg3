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

/// CustomPainter that draws the stylized α (alpha) mark using stroke-based geometry.
///
/// The mark consists of:
/// 1. A thick arc (nearly-closed circle) forming the O-body with a gap on the upper-right
/// 2. A vertically elongated oval counter/eye inside the O-body
/// 3. Two tail strokes from the gap: upper goes up-right, lower goes down-right (X-tail)
///
/// Matches the Alpha Connect reference branding exactly — perfectly upright, no rotation.
class _AlphaMarkPainter extends CustomPainter {
  _AlphaMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. The O-body: thick arc (nearly full circle) with gap on upper-right.
    // Center the O slightly left to leave room for the X-tail.
    final oCenter = Offset(w * 0.37, h * 0.50);
    final oRadius = w * 0.30;
    final oRect = Rect.fromCircle(center: oCenter, radius: oRadius);

    // Arc from ~50° (below gap) sweeping 300° counter-clockwise back to ~350° (above gap).
    // Gap is on the upper-right from about -10° to +50° (350° to 50°).
    // startAngle: 50° = 0.873 rad, sweepAngle: 300° = 5.236 rad
    final oPath = Path();
    oPath.addArc(oRect, 0.87, 5.24);
    canvas.drawPath(oPath, strokePaint);

    // 2. Inner counter (the vertically elongated oval "eye").
    // Drawn with a thinner stroke to create the elongated hole visible in the reference.
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;

    final eyeCenter = Offset(w * 0.37, h * 0.50);
    final eyeRect = Rect.fromCenter(
      center: eyeCenter,
      width: w * 0.22,
      height: h * 0.42,
    );
    final eyePath = Path();
    eyePath.addOval(eyeRect);
    canvas.drawPath(eyePath, eyePaint);

    // 3. Upper tail stroke: from upper-right of O gap, curving up-right.
    final upperTail = Path();
    upperTail.moveTo(w * 0.61, h * 0.26);
    upperTail.cubicTo(
      w * 0.70, h * 0.18,
      w * 0.80, h * 0.10,
      w * 0.92, h * 0.04,
    );
    canvas.drawPath(upperTail, strokePaint);

    // 4. Lower tail stroke: from lower-right of O gap, curving down-right.
    final lowerTail = Path();
    lowerTail.moveTo(w * 0.61, h * 0.74);
    lowerTail.cubicTo(
      w * 0.70, h * 0.82,
      w * 0.80, h * 0.90,
      w * 0.92, h * 0.97,
    );
    canvas.drawPath(lowerTail, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _AlphaMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
