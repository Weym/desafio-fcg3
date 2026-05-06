import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'document_provider.dart';
import 'appointment_provider.dart';

part 'notification_provider.g.dart';

enum NotificationType { documentStatus, appointmentReminder, errorAlert }

class DerivedNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  const DerivedNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

@riverpod
Future<List<DerivedNotification>> derivedNotifications(Ref ref) async {
  final docs = await ref.watch(documentsProvider.future);
  final appointments = await ref.watch(appointmentsProvider.future);

  final notifications = <DerivedNotification>[];
  final now = DateTime.now();

  // Source 1 (per D-16): Documents with recently changed status
  // "Recently" = completedAt within last 7 days, or requestedAt within 48h
  for (final doc in docs) {
    if (doc.status == 'ready' && doc.completedAt != null) {
      if (now.difference(doc.completedAt!).inDays <= 7) {
        notifications.add(DerivedNotification(
          id: 'doc-${doc.id}',
          type: NotificationType.documentStatus,
          title: 'Documento pronto',
          subtitle: '${_typeLabel(doc.type)} disponivel para download',
          timestamp: doc.completedAt!,
          icon: Icons.description,
          color: Colors.green,
        ));
      }
    } else if (doc.status == 'processing') {
      notifications.add(DerivedNotification(
        id: 'doc-proc-${doc.id}',
        type: NotificationType.documentStatus,
        title: 'Documento em processamento',
        subtitle: '${_typeLabel(doc.type)} sendo preparado',
        timestamp: doc.requestedAt,
        icon: Icons.description,
        color: Colors.green,
      ));
    }
  }

  // Source 2 (per D-16): Upcoming appointments within 48h
  for (final apt in appointments) {
    if (apt.isUpcoming && apt.slotDate != null) {
      try {
        final aptDate = DateTime.parse(apt.slotDate!);
        if (aptDate.difference(now).inHours <= 48 && aptDate.isAfter(now)) {
          notifications.add(DerivedNotification(
            id: 'apt-${apt.id}',
            type: NotificationType.appointmentReminder,
            title: 'Agendamento proximo',
            subtitle: '${apt.reason} — ${apt.slotDate} ${apt.slotStartTime ?? ""}',
            timestamp: aptDate,
            icon: Icons.access_time,
            color: Colors.blue,
          ));
        }
      } catch (_) {
        // Skip malformed dates
      }
    }
  }

  // Sort by timestamp descending (most recent first)
  notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return notifications;
}

String _typeLabel(String type) => switch (type) {
      'transcript' => 'Historico Escolar',
      'enrollment_proof' => 'Comprovante de Matricula',
      'declaration' => 'Declaracao',
      'certificate' => 'Certificado',
      _ => type,
    };
