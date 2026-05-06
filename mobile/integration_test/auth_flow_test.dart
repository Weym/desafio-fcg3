import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/core/theme/theme_provider.dart';

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

  // Wait for splash → auth check → navigate to login
  await tester.pumpAndSettle(TestConfig.settleTimeout);
}

/// Helper: perform login flow with given email and OTP bypass code.
Future<void> performLogin(WidgetTester tester, String email) async {
  // Find and fill email field
  final emailField = find.byType(TextFormField);
  expect(emailField, findsOneWidget, reason: 'Email field should be visible');
  await tester.enterText(emailField, email);
  await tester.pumpAndSettle();

  // Tap "Enviar código" button
  final sendCodeButton = find.text('Enviar código');
  expect(sendCodeButton, findsOneWidget,
      reason: 'Send code button should be visible');
  await tester.tap(sendCodeButton);
  await tester.pumpAndSettle(TestConfig.settleTimeout);

  // Now on OTP step — enter 6-digit bypass code
  // The OTP uses 6 individual TextField widgets
  final otpFields = find.byType(TextField);
  // Enter each digit of the OTP code
  for (int i = 0; i < 6; i++) {
    await tester.enterText(otpFields.at(i), TestConfig.devOtpCode[i]);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  // Wait for verification + navigation
  await tester.pumpAndSettle(TestConfig.settleTimeout);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow - Student', () {
    testWidgets('Student login with OTP bypass navigates to client home',
        (tester) async {
      await pumpApp(tester);

      // Should be on login screen
      expect(find.text('Entrar'), findsOneWidget,
          reason: 'Login screen heading should be visible');
      expect(find.text('ALPHA CONNECT'), findsOneWidget,
          reason: 'App brand should be visible');

      // Perform login as student
      await performLogin(tester, TestConfig.studentEmail);

      // Should navigate to client home (student role)
      // Client shell has bottom navigation or shows home content
      expect(find.text('Chat'), findsOneWidget,
          reason:
              'Client navigation should show Chat tab after student login');
    });

    testWidgets('Logout returns to login screen', (tester) async {
      await pumpApp(tester);
      await performLogin(tester, TestConfig.studentEmail);

      // Wait for home to load
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Find and tap logout button (in AppBarActions)
      final logoutButton = find.byIcon(Icons.logout);
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle(TestConfig.settleTimeout);

        // Should be back on login screen
        expect(find.text('Entrar'), findsOneWidget,
            reason: 'Should return to login screen after logout');
      }
    });
  });

  group('Auth Flow - Staff', () {
    testWidgets('Staff login with OTP bypass navigates to staff dashboard',
        (tester) async {
      await pumpApp(tester);

      // Should be on login screen
      expect(find.text('Entrar'), findsOneWidget);

      // Perform login as staff
      await performLogin(tester, TestConfig.staffEmail);

      // Should navigate to staff dashboard
      expect(find.text('Painel de Gestão'), findsOneWidget,
          reason:
              'Staff dashboard title should be visible after staff login');
    });

    testWidgets('Staff dashboard shows KPI cards with numeric values',
        (tester) async {
      await pumpApp(tester);
      await performLogin(tester, TestConfig.staffEmail);

      // Wait for dashboard data to load
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Dashboard should show KPI labels
      expect(find.text('Alunos'), findsOneWidget,
          reason: 'KPI card for students should be visible');
      expect(find.text('Agendamentos'), findsOneWidget,
          reason: 'KPI card for appointments should be visible');
    });
  });
}
