import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/app_empty_state.dart';
import 'package:frontend/shared/widgets/app_error_state.dart';
import 'package:frontend/shared/widgets/app_skeleton_card.dart';
import 'package:frontend/shared/widgets/app_skeleton_chat.dart';
import 'package:frontend/shared/widgets/app_skeleton_list.dart';
import 'package:frontend/shared/widgets/responsive_container.dart';
import 'package:shimmer/shimmer.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSkeletonList', () {
    testWidgets('wraps items in a Shimmer', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonList()));
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders the configured number of items (itemCount)',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonList(itemCount: 3)));

      // AppSkeletonList builds one Container per item wrapped in Padding
      // inside a Column. Count direct Container children with BoxDecoration.
      final containers = find.descendant(
        of: find.byType(Shimmer),
        matching: find.byType(Container),
      );
      expect(containers, findsNWidgets(3));
    });

    testWidgets('uses default itemCount = 5 when not provided',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonList()));

      final containers = find.descendant(
        of: find.byType(Shimmer),
        matching: find.byType(Container),
      );
      expect(containers, findsNWidgets(5));
    });
  });

  group('AppSkeletonCard', () {
    testWidgets('renders inside a Shimmer', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonCard()));
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('applies configured height to the inner Container',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSkeletonCard(height: 150, width: 200)),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Shimmer),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxHeight, 150);
    });
  });

  group('AppEmptyState', () {
    testWidgets('renders icon and message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: Icons.inbox_outlined,
            message: 'Nada aqui',
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('Nada aqui'), findsOneWidget);
    });

    testWidgets('does not render action button when actionLabel is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: Icons.inbox_outlined,
            message: 'Vazio',
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets(
        'renders action button and invokes callback when actionLabel + onAction provided',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: Icons.inbox_outlined,
            message: 'Vazio',
            actionLabel: 'Adicionar',
            onAction: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Adicionar'), findsOneWidget);

      await tester.tap(find.text('Adicionar'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('AppErrorState', () {
    testWidgets('uses default message "Erro ao carregar dados"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(AppErrorState(onRetry: () {})),
      );
      expect(find.text('Erro ao carregar dados'), findsOneWidget);
    });

    testWidgets('uses default retry label "Tentar novamente"', (tester) async {
      await tester.pumpWidget(
        _wrap(AppErrorState(onRetry: () {})),
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('invokes onRetry when retry button is tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(AppErrorState(onRetry: () => retried = true)),
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('accepts custom message override', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppErrorState(
            message: 'Falha na conexao',
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Falha na conexao'), findsOneWidget);
      expect(find.text('Erro ao carregar dados'), findsNothing);
    });
  });

  group('ResponsiveContainer', () {
    testWidgets('applies default maxWidth of 720 via ConstrainedBox',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ResponsiveContainer(
            child: Text('content'),
          ),
        ),
      );

      final constrained = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.text('content'),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(constrained.constraints.maxWidth, 720);
    });

    testWidgets('respects custom maxWidth', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ResponsiveContainer(
            maxWidth: 500,
            child: Text('content'),
          ),
        ),
      );

      final constrained = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.text('content'),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(constrained.constraints.maxWidth, 500);
    });

    testWidgets('centers child via a Center ancestor', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ResponsiveContainer(
            child: Text('content'),
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.text('content'),
          matching: find.byType(Center),
        ),
        findsWidgets,
      );
    });

    testWidgets(
        'constrains rendered child width to maxWidth when viewport is wider',
        (tester) async {
      // Pump at a wide viewport (desktop-ish).
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          ResponsiveContainer(
            maxWidth: 720,
            child: Container(
              key: const Key('child'),
              color: Colors.red,
              child: const SizedBox(width: double.infinity, height: 50),
            ),
          ),
        ),
      );

      final childBox =
          tester.renderObject(find.byKey(const Key('child'))) as RenderBox;
      // Child should not exceed maxWidth.
      expect(childBox.size.width, lessThanOrEqualTo(720));
    });
  });

  group('AppSkeletonChat', () {
    testWidgets('wraps content in a Shimmer', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonChat()));
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders default 7 skeleton bars', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonChat()));
      final aligns = find.descendant(
        of: find.byType(Shimmer),
        matching: find.byType(Align),
      );
      expect(aligns, findsNWidgets(7));
    });

    testWidgets('renders custom itemCount', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonChat(itemCount: 4)));
      final aligns = find.descendant(
        of: find.byType(Shimmer),
        matching: find.byType(Align),
      );
      expect(aligns, findsNWidgets(4));
    });

    testWidgets('alternates left and right alignment', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonChat(itemCount: 4)));
      final aligns = tester.widgetList<Align>(
        find.descendant(
          of: find.byType(Shimmer),
          matching: find.byType(Align),
        ),
      ).toList();
      // Even indices (0, 2) = centerLeft, odd (1, 3) = centerRight
      expect(aligns[0].alignment, Alignment.centerLeft);
      expect(aligns[1].alignment, Alignment.centerRight);
      expect(aligns[2].alignment, Alignment.centerLeft);
      expect(aligns[3].alignment, Alignment.centerRight);
    });
  });
}
