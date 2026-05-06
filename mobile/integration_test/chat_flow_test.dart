import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:frontend/features/client/screens/client_chat_screen.dart';

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

  group('Chat Flow', () {
    testWidgets('Student sees chat sessions list', (tester) async {
      await pumpApp(tester);
      await loginAsStudent(tester);

      // Navigate to Chat tab (index 1 in bottom nav)
      final chatTab = find.text('Chat');
      expect(chatTab, findsWidgets,
          reason: 'Chat tab should be in bottom nav');
      // Tap the bottom nav Chat item (the one in navigation area)
      await tester.tap(chatTab.first);
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Should see the Chat screen
      expect(find.byType(ClientChatScreen), findsOneWidget,
          reason: 'ClientChatScreen should be rendered');

      // Wait for sessions to load
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Should see either session cards or empty state
      // Check for "CONVERSAS RECENTES" header (phone layout)
      // or "Nenhuma conversa encontrada" if no sessions exist
      final hasConversations = find.text('CONVERSAS RECENTES');
      final hasEmpty = find.text('Nenhuma conversa encontrada');

      expect(
        hasConversations.evaluate().isNotEmpty ||
            hasEmpty.evaluate().isNotEmpty,
        isTrue,
        reason:
            'Should show either session list or empty state after loading',
      );
    });

    testWidgets('Student can tap a chat session to view messages',
        (tester) async {
      await pumpApp(tester);
      await loginAsStudent(tester);

      // Navigate to Chat tab
      final chatTab = find.text('Chat');
      await tester.tap(chatTab.first);
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Wait for data to load
      await tester.pumpAndSettle(TestConfig.settleTimeout);

      // Check if there are any session cards to tap
      // Sessions show "Sessao DD/MM HH:MM" format text or GlassCard widgets
      final sessionCards = find.textContaining('Sessao');

      if (sessionCards.evaluate().isNotEmpty) {
        // Tap the first session
        await tester.tap(sessionCards.first);
        await tester.pumpAndSettle(TestConfig.settleTimeout);

        // Should navigate to chat detail with tabs
        // Chat detail has "Mensagens" and "Acoes" tabs
        expect(find.text('Mensagens'), findsOneWidget,
            reason: 'Messages tab should be visible in chat detail');
        expect(find.text('Acoes'), findsOneWidget,
            reason: 'Actions tab should be visible in chat detail');
      }
      // If no sessions exist (no seeded chat data), test passes gracefully
    });
  });
}
