import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
