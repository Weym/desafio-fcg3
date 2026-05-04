import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../providers/document_provider.dart';
import '../providers/appointment_provider.dart';

class ClientNotificationsScreen extends ConsumerWidget {
  const ClientNotificationsScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(documentsProvider);
    ref.invalidate(appointmentsProvider);
    await Future.wait([
      ref.read(documentsProvider.future),
      ref.read(appointmentsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(derivedNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificacoes'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar notificacoes',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _onRefresh(ref),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sem notificacoes no momento',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) =>
                  _NotificationItem(notification: notifications[index]),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final DerivedNotification notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.color.withValues(alpha: 0.1),
        child: Icon(
          notification.icon,
          color: notification.color,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      subtitle: Text(
        notification.subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Text(
        _formatRelativeTime(notification.timestamp),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.isNegative) {
    // Future timestamps (upcoming appointments)
    final absDiff = timestamp.difference(DateTime.now());
    if (absDiff.inMinutes < 60) return 'em ${absDiff.inMinutes}min';
    if (absDiff.inHours < 24) return 'em ${absDiff.inHours}h';
    if (absDiff.inDays < 7) return 'em ${absDiff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }
  if (diff.inMinutes < 60) return 'ha ${diff.inMinutes}min';
  if (diff.inHours < 24) return 'ha ${diff.inHours}h';
  if (diff.inDays < 7) return 'ha ${diff.inDays}d';
  return '${timestamp.day}/${timestamp.month}';
}
