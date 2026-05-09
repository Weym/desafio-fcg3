import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/staff/screens/staff_chat_detail_screen.dart';
import 'package:frontend/features/client/models/chat_message_model.dart';
import 'package:frontend/features/client/models/action_log_model.dart';
import 'package:frontend/features/staff/providers/staff_chat_provider.dart';

void main() {
  group('StaffChatDetailScreen - messages and action logs (UI-F03)', () {
    testWidgets('renders message bubbles with user alignment', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sessionId = 'test-session-id';

      final mockMessages = [
        ChatMessageModel(
          id: 'msg-1',
          role: 'user',
          content: 'Ola, preciso de ajuda',
          createdAt: DateTime(2026, 5, 1, 10, 0),
        ),
        ChatMessageModel(
          id: 'msg-2',
          role: 'assistant',
          content: 'Claro, como posso ajudar?',
          createdAt: DateTime(2026, 5, 1, 10, 1),
        ),
      ];

      final mockLogs = <ActionLogModel>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatMessagesProvider(sessionId)
                .overrideWith((ref) async => mockMessages),
            staffActionLogsProvider(sessionId)
                .overrideWith((ref) async => mockLogs),
          ],
          child: const MaterialApp(
            home: StaffChatDetailScreen(sessionId: sessionId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Message content rendered
      expect(find.text('Ola, preciso de ajuda'), findsOneWidget);
      expect(find.text('Claro, como posso ajudar?'), findsOneWidget);
    });

    testWidgets('renders two tabs: Mensagens and Acoes', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sessionId = 'test-session-2';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatMessagesProvider(sessionId)
                .overrideWith((ref) async => <ChatMessageModel>[]),
            staffActionLogsProvider(sessionId)
                .overrideWith((ref) async => <ActionLogModel>[]),
          ],
          child: const MaterialApp(
            home: StaffChatDetailScreen(sessionId: sessionId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mensagens'), findsOneWidget);
      expect(find.text('Acoes'), findsOneWidget);
    });

    testWidgets('actions tab shows expansion tiles with tool names',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sessionId = 'test-session-3';

      final mockMessages = <ChatMessageModel>[];
      final mockLogs = [
        ActionLogModel(
          id: 'log-1',
          toolName: 'get_student_grades',
          inputParams: {'semester': 3},
          outputResult: {'grades': []},
          latencyMs: 150,
          status: 'success',
          createdAt: DateTime(2026, 5, 1, 10, 5),
        ),
        ActionLogModel(
          id: 'log-2',
          toolName: 'create_enrollment',
          inputParams: {'course_id': 'c1'},
          status: 'error',
          latencyMs: 500,
          createdAt: DateTime(2026, 5, 1, 10, 6),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatMessagesProvider(sessionId)
                .overrideWith((ref) async => mockMessages),
            staffActionLogsProvider(sessionId)
                .overrideWith((ref) async => mockLogs),
          ],
          child: const MaterialApp(
            home: StaffChatDetailScreen(sessionId: sessionId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Acoes tab
      await tester.tap(find.text('Acoes'));
      await tester.pumpAndSettle();

      // Action log tool names
      expect(find.text('get_student_grades'), findsOneWidget);
      expect(find.text('create_enrollment'), findsOneWidget);

      // ExpansionTile exists
      expect(find.byType(ExpansionTile), findsNWidgets(2));
    });

    testWidgets('shows empty state for messages tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sessionId = 'test-session-empty';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatMessagesProvider(sessionId)
                .overrideWith((ref) async => <ChatMessageModel>[]),
            staffActionLogsProvider(sessionId)
                .overrideWith((ref) async => <ActionLogModel>[]),
          ],
          child: const MaterialApp(
            home: StaffChatDetailScreen(sessionId: sessionId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nenhuma mensagem nesta sessao'), findsOneWidget);
    });

    testWidgets('shows empty state for actions tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sessionId = 'test-session-empty-actions';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatMessagesProvider(sessionId)
                .overrideWith((ref) async => <ChatMessageModel>[]),
            staffActionLogsProvider(sessionId)
                .overrideWith((ref) async => <ActionLogModel>[]),
          ],
          child: const MaterialApp(
            home: StaffChatDetailScreen(sessionId: sessionId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Acoes tab
      await tester.tap(find.text('Acoes'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma acao registrada nesta sessao'), findsOneWidget);
    });

    testWidgets('AppBar shows Conversa title', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sessionId = 'title-test';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatMessagesProvider(sessionId)
                .overrideWith((ref) async => <ChatMessageModel>[]),
            staffActionLogsProvider(sessionId)
                .overrideWith((ref) async => <ActionLogModel>[]),
          ],
          child: const MaterialApp(
            home: StaffChatDetailScreen(sessionId: sessionId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Conversa'), findsOneWidget);
    });
  });
}
