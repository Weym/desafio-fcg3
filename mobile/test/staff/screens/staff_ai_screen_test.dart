import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/staff/screens/staff_ai_screen.dart';
import 'package:frontend/features/client/models/chat_session_model.dart';
import 'package:frontend/features/staff/providers/staff_chat_provider.dart';

void main() {
  group('StaffAiScreen - Sessions and Statistics tabs (UI-F03)', () {
    testWidgets('renders two tabs: Sessoes and Estatisticas', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = <ChatSessionModel>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatSessionsProvider
                .overrideWith((ref) async => mockSessions),
            staffChatStatisticsProvider.overrideWith((ref) async => {
                  'total_sessions': 0,
                  'active_sessions': 0,
                  'closed_sessions': 0,
                }),
          ],
          child: const MaterialApp(
            home: StaffAiScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab labels - using unicode chars as they appear in the implementation
      expect(find.text('Sessões'), findsOneWidget);
      expect(find.text('Estatísticas'), findsOneWidget);
    });

    testWidgets('sessions tab shows session cards with status badges',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        ChatSessionModel(
          id: '11111111-1111-1111-1111-111111111111',
          status: 'active',
          startedAt: DateTime(2026, 5, 1, 10, 0),
          whatsappPhone: '+5511999001122',
        ),
        ChatSessionModel(
          id: '22222222-2222-2222-2222-222222222222',
          status: 'closed',
          startedAt: DateTime(2026, 4, 28, 14, 30),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatSessionsProvider
                .overrideWith((ref) async => mockSessions),
            staffChatStatisticsProvider.overrideWith((ref) async => {
                  'total_sessions': 2,
                  'active_sessions': 1,
                  'closed_sessions': 1,
                }),
          ],
          child: const MaterialApp(
            home: StaffAiScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Session card with phone number
      expect(find.text('+5511999001122'), findsOneWidget);

      // Session card without phone (shows truncated id)
      expect(find.text('Sessão #22222222'), findsOneWidget);

      // Status badges
      expect(find.text('Ativa'), findsOneWidget);
      expect(find.text('Encerrada'), findsOneWidget);
    });

    testWidgets('statistics tab shows session counters', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        ChatSessionModel(
          id: 'x',
          status: 'active',
          startedAt: DateTime(2026, 5, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatSessionsProvider
                .overrideWith((ref) async => mockSessions),
            staffChatStatisticsProvider.overrideWith((ref) async => {
                  'total_sessions': 15,
                  'active_sessions': 5,
                  'closed_sessions': 10,
                }),
          ],
          child: const MaterialApp(
            home: StaffAiScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to statistics tab
      await tester.tap(find.text('Estatísticas'));
      await tester.pumpAndSettle();

      // Statistics labels
      expect(find.text('Total de Sessões'), findsOneWidget);
      expect(find.text('Sessões Ativas'), findsOneWidget);
      expect(find.text('Sessões Encerradas'), findsOneWidget);

      // Statistics values
      expect(find.text('15'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatSessionsProvider
                .overrideWith((ref) async => <ChatSessionModel>[]),
            staffChatStatisticsProvider.overrideWith((ref) async => {
                  'total_sessions': 0,
                  'active_sessions': 0,
                  'closed_sessions': 0,
                }),
          ],
          child: const MaterialApp(
            home: StaffAiScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nenhuma conversa encontrada'), findsOneWidget);
    });

    testWidgets('shows AppBar with title Insights IA', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffChatSessionsProvider
                .overrideWith((ref) async => <ChatSessionModel>[]),
            staffChatStatisticsProvider.overrideWith((ref) async => {
                  'total_sessions': 0,
                  'active_sessions': 0,
                  'closed_sessions': 0,
                }),
          ],
          child: const MaterialApp(
            home: StaffAiScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Insights IA'), findsOneWidget);
    });
  });
}
