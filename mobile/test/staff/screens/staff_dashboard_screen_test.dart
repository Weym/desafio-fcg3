import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/staff/screens/staff_dashboard_screen.dart';
import 'package:frontend/features/staff/models/staff_dashboard_model.dart';
import 'package:frontend/features/staff/providers/staff_dashboard_provider.dart';

void main() {
  group('StaffDashboardScreen - KPI cards rendering (UI-F01)', () {
    testWidgets('renders KPI cards with correct values when data loads',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockDashboard = StaffDashboardModel(
        totalStudents: 120,
        activeEnrollments: 95,
        pendingDocuments: 12,
        upcomingAppointments: 5,
        activeChatSessions: 3,
        enrollmentPeriod: EnrollmentPeriodInfo(
          name: '2026.1 - Primeiro Semestre',
          isActive: true,
          daysRemaining: 15,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDashboardProvider.overrideWith((ref) async => mockDashboard),
          ],
          child: const MaterialApp(
            home: StaffDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify KPI values are displayed
      expect(find.text('120'), findsOneWidget); // totalStudents
      expect(find.text('3'), findsOneWidget); // activeChatSessions
      expect(find.text('12'), findsOneWidget); // pendingDocuments
      expect(find.text('5'), findsOneWidget); // upcomingAppointments
    });

    testWidgets('renders enrollment period banner when active', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockDashboard = StaffDashboardModel(
        totalStudents: 50,
        activeEnrollments: 30,
        pendingDocuments: 2,
        upcomingAppointments: 1,
        activeChatSessions: 0,
        enrollmentPeriod: EnrollmentPeriodInfo(
          name: 'Periodo Matricula 2026.1',
          isActive: true,
          daysRemaining: 7,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDashboardProvider.overrideWith((ref) async => mockDashboard),
          ],
          child: const MaterialApp(
            home: StaffDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enrollment banner elements
      expect(find.text('Periodo Matricula 2026.1'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('7 dias restantes'), findsOneWidget);
    });

    testWidgets('does not show enrollment banner when period is null',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockDashboard = StaffDashboardModel(
        totalStudents: 10,
        activeEnrollments: 5,
        pendingDocuments: 0,
        upcomingAppointments: 0,
        activeChatSessions: 0,
        enrollmentPeriod: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDashboardProvider.overrideWith((ref) async => mockDashboard),
          ],
          child: const MaterialApp(
            home: StaffDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT find enrollment-specific text
      expect(find.text('Ativo'), findsNothing);
      expect(find.textContaining('dias restantes'), findsNothing);
    });

    testWidgets('shows KPI card labels', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockDashboard = StaffDashboardModel(
        totalStudents: 100,
        activeEnrollments: 80,
        pendingDocuments: 5,
        upcomingAppointments: 2,
        activeChatSessions: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDashboardProvider.overrideWith((ref) async => mockDashboard),
          ],
          child: const MaterialApp(
            home: StaffDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card labels are present
      expect(find.text('Alunos'), findsOneWidget);
      expect(find.text('Chats Hoje'), findsOneWidget);
      expect(find.text('Docs Pendentes'), findsOneWidget);
      expect(find.text('Agendamentos'), findsOneWidget);
    });

    testWidgets('shows AppBar with correct title', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockDashboard = StaffDashboardModel(
        totalStudents: 0,
        activeEnrollments: 0,
        pendingDocuments: 0,
        upcomingAppointments: 0,
        activeChatSessions: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDashboardProvider.overrideWith((ref) async => mockDashboard),
          ],
          child: const MaterialApp(
            home: StaffDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Painel de Gestão'), findsOneWidget);
    });
  });
}
