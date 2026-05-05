/// Responsive breakpoint constants for adaptive layout.
///
/// Three-tier breakpoints:
/// - Phone: < 600dp
/// - Tablet: 600–1023dp
/// - Desktop: >= 1024dp
class AppBreakpoints {
  static const double phone = 600; // < 600dp = phone
  static const double tablet = 1024; // 600-1023dp = tablet, >= 1024dp = desktop

  static bool isPhone(double width) => width < phone;
  static bool isTablet(double width) => width >= phone && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}
