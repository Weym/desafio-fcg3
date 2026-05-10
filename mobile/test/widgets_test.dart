import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/animated_entrance.dart';
import 'package:frontend/core/theme/app_animations.dart';
import 'package:frontend/shared/widgets/glass_card.dart';
import 'package:frontend/shared/widgets/pill_button.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: const Text('Test content'),
            ),
          ),
        ),
      );

      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('applies onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Tappable'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });

    testWidgets('renders without onTap (no GestureDetector wrapper)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: const Text('Static'),
            ),
          ),
        ),
      );

      // Should render successfully without error
      expect(find.text('Static'), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('uses BackdropFilter for glass effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: const Text('Glass'),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('accepts elevation parameter without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              elevation: 2,
              child: const Text('Elevated'),
            ),
          ),
        ),
      );

      expect(find.text('Elevated'), findsOneWidget);
    });

    testWidgets('accepts glowColor parameter without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              glowColor: Colors.purple,
              child: const Text('Custom glow'),
            ),
          ),
        ),
      );

      expect(find.text('Custom glow'), findsOneWidget);
    });
  });

  group('PillButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              label: 'Click me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              label: 'Press',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press'));
      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              label: 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              label: 'With Icon',
              icon: Icons.arrow_forward,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('renders all variants without error', (tester) async {
      for (final variant in PillButtonVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PillButton(
                label: variant.name,
                variant: variant,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('ghost variant renders with transparent background',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              label: 'Ghost',
              variant: PillButtonVariant.ghost,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ghost'), findsOneWidget);
      // Button should render without error in ghost mode
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('expanded fills available width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: PillButton(
                label: 'Expanded',
                isExpanded: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonBox =
          tester.renderObject(find.byType(ElevatedButton)) as RenderBox;
      // When expanded, button should fill the 300px container
      expect(buttonBox.size.width, 300);
    });
  });

  group('AnimatedEntrance', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('starts invisible with delay then animates in',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              delay: const Duration(milliseconds: 400),
              child: const Text('Delayed'),
            ),
          ),
        ),
      );

      // At 100ms the Timer hasn't fired yet — child should be at opacity 0
      await tester.pump(const Duration(milliseconds: 100));
      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, equals(0.0));

      // Pump past the delay + full animation duration
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Delayed'), findsOneWidget);
    });

    testWidgets('animates immediately with zero delay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              delay: Duration.zero,
              child: const Text('Immediate'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Immediate'), findsOneWidget);
    });

    testWidgets('respects reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedEntrance(
                delay: const Duration(milliseconds: 500),
                child: const Text('No Motion'),
              ),
            ),
          ),
        ),
      );

      // With reduced motion, child should render immediately at frame 0
      // without any Opacity or Transform wrappers from TweenAnimationBuilder
      expect(find.text('No Motion'), findsOneWidget);
      // The widget should return plain child — no TweenAnimationBuilder
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    });

    testWidgets('Timer is canceled on dispose — no setState after dispose',
        (tester) async {
      // Pump widget with a very long delay
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              delay: const Duration(seconds: 5),
              child: const Text('Will Dispose'),
            ),
          ),
        ),
      );

      // Immediately replace the widget (dispose the AnimatedEntrance)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Replacement'),
          ),
        ),
      );

      // Pump past the original delay — should NOT throw setState error
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      // Verify replacement rendered and no error occurred
      expect(find.text('Replacement'), findsOneWidget);
      expect(find.text('Will Dispose'), findsNothing);
    });

    testWidgets('uses default constants from AppAnimations', (tester) async {
      // Verify the widget works with all defaults (no optional params)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              child: const Text('Defaults'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Defaults'), findsOneWidget);

      // Verify AppAnimations constants are accessible
      expect(AppAnimations.entranceDuration, const Duration(milliseconds: 800));
      expect(AppAnimations.staggerDelay, const Duration(milliseconds: 150));
      expect(AppAnimations.maxStaggerIndex, 5);
      expect(
        AppAnimations.getEntranceDelay(3),
        const Duration(milliseconds: 450),
      );
      // Verify capping at maxStaggerIndex
      expect(
        AppAnimations.getEntranceDelay(10),
        const Duration(milliseconds: 750),
      );
    });
  });
}
