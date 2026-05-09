import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/client/models/document_model.dart';
import 'package:frontend/features/client/models/appointment_model.dart';
import 'package:frontend/features/client/providers/notification_provider.dart';
import 'package:frontend/features/client/providers/document_provider.dart';
import 'package:frontend/features/client/providers/appointment_provider.dart';

void main() {
  group('derivedNotificationsProvider derives notifications correctly', () {
    test('user sees notification for document completed within 7 days',
        () async {
      final now = DateTime.now();
      final recentCompletion = now.subtract(const Duration(days: 3));

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => [
              DocumentModel(
                id: 'doc-001',
                type: 'transcript',
                status: 'ready',
                fileUrl: 'https://example.com/doc.pdf',
                notes: null,
                requestedAt: now.subtract(const Duration(days: 10)),
                completedAt: recentCompletion,
              ),
            ]),
        appointmentsProvider.overrideWith((ref) async => []),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      expect(notifications, hasLength(1));
      expect(notifications.first.type, NotificationType.documentStatus);
      expect(notifications.first.title, 'Documento pronto');
      expect(notifications.first.subtitle, contains('Historico Escolar'));
    });

    test('user does NOT see notification for document completed over 7 days ago',
        () async {
      final now = DateTime.now();
      final oldCompletion = now.subtract(const Duration(days: 10));

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => [
              DocumentModel(
                id: 'doc-old',
                type: 'transcript',
                status: 'ready',
                fileUrl: 'https://example.com/doc.pdf',
                notes: null,
                requestedAt: now.subtract(const Duration(days: 20)),
                completedAt: oldCompletion,
              ),
            ]),
        appointmentsProvider.overrideWith((ref) async => []),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      expect(notifications, isEmpty);
    });

    test('user sees notification for document in processing status', () async {
      final now = DateTime.now();

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => [
              DocumentModel(
                id: 'doc-proc',
                type: 'enrollment_proof',
                status: 'processing',
                fileUrl: null,
                notes: null,
                requestedAt: now.subtract(const Duration(hours: 12)),
                completedAt: null,
              ),
            ]),
        appointmentsProvider.overrideWith((ref) async => []),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      expect(notifications, hasLength(1));
      expect(notifications.first.title, 'Documento em processamento');
      expect(
          notifications.first.subtitle, contains('Comprovante de Matricula'));
    });

    test('user sees notification for appointment within 48 hours', () async {
      final now = DateTime.now();
      final upcomingDate = now.add(const Duration(hours: 24));

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => []),
        appointmentsProvider.overrideWith((ref) async => [
              AppointmentModel(
                id: 'apt-001',
                slotId: 'slot-1',
                reason: 'Reuniao com coordenador',
                status: 'scheduled',
                slotDate: upcomingDate.toIso8601String().split('T').first,
                slotStartTime: '14:00',
                endTime: '14:30',
                createdAt: now.subtract(const Duration(days: 2)),
              ),
            ]),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      expect(notifications, hasLength(1));
      expect(notifications.first.type, NotificationType.appointmentReminder);
      expect(notifications.first.title, 'Agendamento proximo');
      expect(notifications.first.subtitle, contains('Reuniao com coordenador'));
    });

    test('user does NOT see notification for appointment beyond 48 hours',
        () async {
      final now = DateTime.now();
      final farDate = now.add(const Duration(hours: 72));

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => []),
        appointmentsProvider.overrideWith((ref) async => [
              AppointmentModel(
                id: 'apt-far',
                slotId: 'slot-2',
                reason: 'Reuniao distante',
                status: 'scheduled',
                slotDate: farDate.toIso8601String().split('T').first,
                slotStartTime: '10:00',
                endTime: '10:30',
                createdAt: now.subtract(const Duration(days: 1)),
              ),
            ]),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      expect(notifications, isEmpty);
    });

    test('user does NOT see notification for cancelled appointment', () async {
      final now = DateTime.now();
      final upcomingDate = now.add(const Duration(hours: 12));

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => []),
        appointmentsProvider.overrideWith((ref) async => [
              AppointmentModel(
                id: 'apt-cancelled',
                slotId: 'slot-3',
                reason: 'Cancelada',
                status: 'cancelled',
                slotDate: upcomingDate.toIso8601String().split('T').first,
                slotStartTime: '10:00',
                endTime: null,
                createdAt: now.subtract(const Duration(days: 1)),
              ),
            ]),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      expect(notifications, isEmpty);
    });

    test('notifications are sorted by timestamp descending', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(days: 1));
      final later = now.subtract(const Duration(hours: 2));
      final upcoming = now.add(const Duration(hours: 6));

      final container = ProviderContainer(overrides: [
        documentsProvider.overrideWith((ref) async => [
              DocumentModel(
                id: 'doc-a',
                type: 'transcript',
                status: 'ready',
                fileUrl: 'https://example.com/a.pdf',
                notes: null,
                requestedAt: now.subtract(const Duration(days: 5)),
                completedAt: earlier,
              ),
              DocumentModel(
                id: 'doc-b',
                type: 'declaration',
                status: 'ready',
                fileUrl: 'https://example.com/b.pdf',
                notes: null,
                requestedAt: now.subtract(const Duration(days: 3)),
                completedAt: later,
              ),
            ]),
        appointmentsProvider.overrideWith((ref) async => [
              AppointmentModel(
                id: 'apt-sort',
                slotId: 'slot-s',
                reason: 'Test',
                status: 'scheduled',
                slotDate: upcoming.toIso8601String().split('T').first,
                slotStartTime: '15:00',
                endTime: null,
                createdAt: now.subtract(const Duration(days: 1)),
              ),
            ]),
      ]);
      addTearDown(container.dispose);

      final notifications =
          await container.read(derivedNotificationsProvider.future);

      // Should be: upcoming appointment (future) > doc-b (2h ago) > doc-a (1d ago)
      expect(notifications.length, greaterThanOrEqualTo(2));
      for (var i = 0; i < notifications.length - 1; i++) {
        expect(
          notifications[i].timestamp.isAfter(notifications[i + 1].timestamp) ||
              notifications[i]
                  .timestamp
                  .isAtSameMomentAs(notifications[i + 1].timestamp),
          isTrue,
          reason: 'Notifications must be sorted descending by timestamp',
        );
      }
    });
  });
}
