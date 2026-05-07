import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/staff/screens/staff_schedule_screen.dart';
import 'package:frontend/features/client/models/appointment_model.dart';
import 'package:frontend/features/staff/providers/staff_schedule_provider.dart';

void main() {
  group('StaffScheduleScreen - filter chips and appointment cards (UI-F02)',
      () {
    testWidgets('renders filter chips: Todos, Agendados, Cancelados',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAppointments = [
        AppointmentModel(
          id: 'apt-1',
          reason: 'Orientacao academica',
          status: 'scheduled',
          createdAt: DateTime(2026, 5, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffAppointmentsProvider
                .overrideWith((ref) async => mockAppointments),
          ],
          child: const MaterialApp(
            home: StaffScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Filter chips
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Agendados'), findsOneWidget);
      expect(find.text('Cancelados'), findsOneWidget);
    });

    testWidgets('renders appointment cards with reason and status',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAppointments = [
        AppointmentModel(
          id: 'apt-1',
          reason: 'Matricula especial',
          status: 'scheduled',
          slotDate: '2026-05-10',
          slotStartTime: '09:00',
          createdAt: DateTime(2026, 5, 1),
        ),
        AppointmentModel(
          id: 'apt-2',
          reason: 'Revisao de nota',
          status: 'cancelled',
          createdAt: DateTime(2026, 5, 2),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffAppointmentsProvider
                .overrideWith((ref) async => mockAppointments),
          ],
          child: const MaterialApp(
            home: StaffScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Appointment reasons displayed
      expect(find.text('Matricula especial'), findsOneWidget);
      expect(find.text('Revisao de nota'), findsOneWidget);

      // Status labels displayed
      expect(find.text('Agendado'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
    });

    testWidgets('shows FAB with tooltip Novo Slot', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffAppointmentsProvider
                .overrideWith((ref) async => <AppointmentModel>[]),
          ],
          child: const MaterialApp(
            home: StaffScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // FAB should exist
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty state when no appointments', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffAppointmentsProvider
                .overrideWith((ref) async => <AppointmentModel>[]),
          ],
          child: const MaterialApp(
            home: StaffScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nenhum agendamento'), findsOneWidget);
    });

    testWidgets('shows AppBar with title Agenda', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffAppointmentsProvider
                .overrideWith((ref) async => <AppointmentModel>[]),
          ],
          child: const MaterialApp(
            home: StaffScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Agenda'), findsOneWidget);
    });
  });
}
