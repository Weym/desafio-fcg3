/// Cyber-Academic Design System — 8px base unit spacing tokens.
///
/// Grid: 8px base unit. All spacing is a multiple of 8.
/// xs=4 (half-unit), sm=8 (1 unit), md=16 (2), lg=24 (3), xl=32 (4), xxl=48 (6).
class AppSpacing {
  // Spacing scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Border radius scale
  static const double radiusSm = 8; // 0.5rem
  static const double radiusMd = 12; // inputs, small cards
  static const double radiusLg = 16; // cards, containers
  static const double radiusXl = 24; // large panels, sheets
  static const double radiusXxl = 32; // pill shapes (not full)
  static const double radiusFull = 999; // full pill / circular
}
