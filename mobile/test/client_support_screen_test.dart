import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/client/screens/client_support_screen.dart';

void main() {
  group('ClientSupportScreen renders contact info and actions', () {
    Widget buildTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: ClientSupportScreen(),
        ),
      );
    }

    testWidgets('user sees support page title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Suporte'), findsWidgets);
    });

    testWidgets('user sees WhatsApp contact option', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('WhatsApp'), findsOneWidget);
    });

    testWidgets('user sees phone contact option', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Ligar'), findsOneWidget);
    });

    testWidgets('user sees email contact option', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('E-mail'), findsOneWidget);
    });

    testWidgets('user sees office hours information', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('08h'), findsOneWidget);
      expect(find.textContaining('21h'), findsOneWidget);
    });

    testWidgets('user sees support agent icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.support_agent), findsOneWidget);
    });

    testWidgets('user sees chevron indicators on contact options',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Three contact options should have chevron right icons
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });
  });
}
