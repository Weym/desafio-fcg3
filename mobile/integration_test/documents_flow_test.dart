import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:frontend/features/client/screens/client_documents_screen.dart';

import 'helpers/test_config.dart';

/// Helper: pump the app with proper SharedPreferences override.
Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AlphaConnectApp(),
    ),
  );

  await tester.pumpAndSettle(TestConfig.settleTimeout);
}

/// Helper: perform login as student (email + OTP bypass).
Future<void> loginAsStudent(WidgetTester tester) async {
  // Enter student email
  final emailField = find.byType(TextFormField);
  expect(emailField, findsOneWidget);
  await tester.enterText(emailField, TestConfig.studentEmail);
  await tester.pumpAndSettle();

  // Tap send code button
  final sendCodeButton = find.widgetWithText(ElevatedButton, 'Enviar codigo');
  expect(sendCodeButton, findsOneWidget);
  await tester.tap(sendCodeButton);
  await tester.pumpAndSettle(TestConfig.settleTimeout);

  // Enter OTP digits
  final otpFields = find.byType(TextField);
  for (int i = 0; i < 6; i++) {
    await tester.enterText(otpFields.at(i), TestConfig.devOtpCode[i]);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  // Wait for navigation to complete
  await tester.pumpAndSettle(TestConfig.settleTimeout);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Documents Flow', () {
    testWidgets('Student sees document list after navigating to Documents tab',
        (tester) async {
      await pumpApp(tester);
      await loginAsStudent(tester);

      // Navigate to Documents tab (index 2 in bottom nav)
      // Find the "Docs" label in bottom navigation
      final docsTab = find.text('Docs');
      expect(docsTab, findsOneWidget,
          reason: 'Documents tab should be in bottom nav');
      await tester.tap(docsTab);
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Should see the Documents screen with title
      expect(find.text('Documentos'), findsOneWidget,
          reason: 'Documents screen title should be visible');

      // Wait for documents to load from API
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Should see filter tabs
      expect(find.text('Ver todos'), findsOneWidget,
          reason: 'Filter tabs should be visible');
      expect(find.text('Pendentes'), findsOneWidget);
      expect(find.text('Prontos'), findsOneWidget);

      // Verify the ClientDocumentsScreen widget is rendered
      expect(find.byType(ClientDocumentsScreen), findsOneWidget,
          reason: 'ClientDocumentsScreen should be rendered');
    });

    testWidgets('Student can open document request sheet', (tester) async {
      await pumpApp(tester);
      await loginAsStudent(tester);

      // Navigate to Documents tab
      final docsTab = find.text('Docs');
      await tester.tap(docsTab);
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Tap the add/request button (filled IconButton with add icon)
      final addButton = find.byTooltip('Solicitar Documento');
      expect(addButton, findsOneWidget,
          reason: 'Document request FAB should be visible');
      await tester.tap(addButton);
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Bottom sheet should appear with "Solicitar Documento" title
      expect(find.text('Solicitar Documento'), findsOneWidget,
          reason: 'Document request sheet should open');

      // Should show document type dropdown
      expect(find.text('Tipo de documento'), findsOneWidget,
          reason: 'Type dropdown should be visible');

      // Should show submit button
      expect(find.text('Solicitar'), findsOneWidget,
          reason: 'Submit button should be visible');
    });
  });
}
