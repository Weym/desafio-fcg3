import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/responsive/breakpoints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBreakpoints constants', () {
    test('phone breakpoint is 600', () {
      expect(AppBreakpoints.phone, 600);
    });

    test('tablet breakpoint is 1024', () {
      expect(AppBreakpoints.tablet, 1024);
    });
  });

  group('AppBreakpoints.isPhone', () {
    test('returns true for widths below 600', () {
      expect(AppBreakpoints.isPhone(0), isTrue);
      expect(AppBreakpoints.isPhone(359), isTrue);
      expect(AppBreakpoints.isPhone(599), isTrue);
    });

    test('returns false at boundary of 600 (tablet start)', () {
      expect(AppBreakpoints.isPhone(600), isFalse);
    });

    test('returns false for tablet and desktop widths', () {
      expect(AppBreakpoints.isPhone(768), isFalse);
      expect(AppBreakpoints.isPhone(1024), isFalse);
      expect(AppBreakpoints.isPhone(1440), isFalse);
    });
  });

  group('AppBreakpoints.isTablet', () {
    test('returns false for phone widths below 600', () {
      expect(AppBreakpoints.isTablet(599), isFalse);
    });

    test('returns true at lower boundary 600', () {
      expect(AppBreakpoints.isTablet(600), isTrue);
    });

    test('returns true for widths within tablet range', () {
      expect(AppBreakpoints.isTablet(768), isTrue);
      expect(AppBreakpoints.isTablet(1023), isTrue);
    });

    test('returns false at upper boundary 1024 (desktop start)', () {
      expect(AppBreakpoints.isTablet(1024), isFalse);
    });

    test('returns false for desktop widths', () {
      expect(AppBreakpoints.isTablet(1200), isFalse);
      expect(AppBreakpoints.isTablet(1920), isFalse);
    });
  });

  group('AppBreakpoints.isDesktop', () {
    test('returns false for widths below 1024', () {
      expect(AppBreakpoints.isDesktop(0), isFalse);
      expect(AppBreakpoints.isDesktop(599), isFalse);
      expect(AppBreakpoints.isDesktop(1023), isFalse);
    });

    test('returns true at lower boundary 1024', () {
      expect(AppBreakpoints.isDesktop(1024), isTrue);
    });

    test('returns true for desktop widths above 1024', () {
      expect(AppBreakpoints.isDesktop(1200), isTrue);
      expect(AppBreakpoints.isDesktop(1920), isTrue);
      expect(AppBreakpoints.isDesktop(3840), isTrue);
    });
  });

  group('AppBreakpoints partitioning (mutual exclusion)', () {
    test('every width classifies to exactly one of phone/tablet/desktop', () {
      for (final width in [0.0, 100, 599, 600, 768, 1023, 1024, 1200, 1920]) {
        final classifications = [
          AppBreakpoints.isPhone(width.toDouble()),
          AppBreakpoints.isTablet(width.toDouble()),
          AppBreakpoints.isDesktop(width.toDouble()),
        ].where((b) => b).length;
        expect(
          classifications,
          1,
          reason: 'width $width must fall into exactly one category',
        );
      }
    });
  });
}
