import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/staff/screens/staff_intervention_screen.dart';
import 'package:frontend/features/staff/models/intervention_session_model.dart';
import 'package:frontend/features/staff/providers/staff_intervention_provider.dart';

/// Creates a mock InterventionSessionModel for testing.
InterventionSessionModel _mockSession({
  required String id,
  required String status,
  String? studentName,
  String? studentEmail,
  String? whatsappPhone,
  String? escalationReason,
  String? assignedStaffId,
  DateTime? startedAt,
}) {
  return InterventionSessionModel(
    id: id,
    status: status,
    studentName: studentName,
    studentEmail: studentEmail,
    whatsappPhone: whatsappPhone,
    escalationReason: escalationReason,
    assignedStaffId: assignedStaffId,
    startedAt: startedAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
  );
}

void main() {
  group('StaffInterventionScreen - session cards rendering (HI-12)', () {
    testWidgets('renders session cards with correct data when sessions exist',
        (tester) async {
      // Use a large surface to avoid RenderFlex overflow
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '11111111-1111-1111-1111-111111111111',
          status: 'human_needed',
          studentName: 'Ana Silva',
          studentEmail: 'ana@test.edu',
          escalationReason: 'Aluno pediu atendente',
        ),
        _mockSession(
          id: '22222222-2222-2222-2222-222222222222',
          status: 'human_active',
          studentName: 'Carlos Santos',
          studentEmail: 'carlos@test.edu',
          assignedStaffId: 'staff-id-1',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      // Wait for async provider to resolve
      await tester.pumpAndSettle();

      // HI-12: Cards should render with student names
      // Pendentes tab shows human_needed sessions
      expect(find.text('Ana Silva'), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions available', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => <InterventionSessionModel>[]),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty message for Pendentes tab (default tab)
      expect(find.text('Nenhuma conversa pendente'), findsOneWidget);
    });
  });

  group('Session card displays details (HI-13)', () {
    testWidgets('shows student name on card', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '33333333-3333-3333-3333-333333333333',
          status: 'human_needed',
          studentName: 'Maria Oliveira',
          studentEmail: 'maria@test.edu',
          escalationReason: 'Preciso de ajuda',
          startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // HI-13: Student name displayed
      expect(find.text('Maria Oliveira'), findsOneWidget);
    });

    testWidgets('shows PENDENTE badge for human_needed session',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '44444444-4444-4444-4444-444444444444',
          status: 'human_needed',
          studentName: 'Pedro Lima',
          studentEmail: 'pedro@test.edu',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // HI-13: Status badge
      expect(find.text('PENDENTE'), findsOneWidget);
    });

    testWidgets('shows EM ATENDIMENTO badge for human_active session',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '55555555-5555-5555-5555-555555555555',
          status: 'human_active',
          studentName: 'Joao Costa',
          studentEmail: 'joao@test.edu',
          assignedStaffId: 'staff-abc',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      // Go to "Em atendimento" tab
      await tester.pumpAndSettle();
      await tester.tap(find.text('Em atendimento'));
      await tester.pumpAndSettle();

      // HI-13: Status badge on active tab
      expect(find.text('EM ATENDIMENTO'), findsOneWidget);
    });

    testWidgets('shows elapsed time indicator', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '66666666-6666-6666-6666-666666666666',
          status: 'human_needed',
          studentName: 'Lucas Ribeiro',
          startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // HI-13: Elapsed time (should show "Xm atrás" or similar)
      expect(find.textContaining('atrás'), findsOneWidget);
    });

    testWidgets('shows Assumir Conversa button only for pending sessions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '77777777-7777-7777-7777-777777777777',
          status: 'human_needed',
          studentName: 'Fernanda Souza',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // HI-13: "Assumir Conversa" button present for pending
      expect(find.text('Assumir Conversa'), findsOneWidget);
    });

    testWidgets('displays student identifier (email)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSessions = [
        _mockSession(
          id: '88888888-8888-8888-8888-888888888888',
          status: 'human_needed',
          studentName: 'Rafael Martins',
          studentEmail: 'rafael@test.edu',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionSessionsProvider
                .overrideWith((ref) async => mockSessions),
          ],
          child: const MaterialApp(
            home: StaffInterventionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // HI-13: Displays student identifier (displayIdentifier = email)
      expect(find.text('rafael@test.edu'), findsOneWidget);
    });
  });
}
