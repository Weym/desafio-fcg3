import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: const [AppBarActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: notificationsAsync.when(
          loading: () => const ResponsiveContainer(
            padding: EdgeInsets.all(16),
            child: AppSkeletonList(itemCount: 5, itemHeight: 72),
          ),
          error: (error, stack) => ListView(
            children: [
              ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  onRetry: () => _onRefresh(ref),
                ),
              ),
            ],
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.notifications_none,
                    message: 'Nenhuma notificação',
                  ),
                ],
              );
            }

            final unreadCount = notifications
                .where((n) => _isRecent(n.timestamp))
                .length;

            return Column(
              children: [
                if (notificationsAsync.isRefreshing)
                  const LinearProgressIndicator(),
                // Header with count
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Você tem $unreadCount novos alertas.',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ResponsiveContainer(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _NotificationCard(
                        notification: notifications[index],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isRecent(DateTime timestamp) {
    return DateTime.now().difference(timestamp).inHours < 24;
  }
}

class _NotificationCard extends StatelessWidget {
  final DerivedNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRecent = DateTime.now().difference(notification.timestamp).inHours < 24;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              notification.icon,
              color: notification.color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: notification.color.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        _categoryLabel(notification),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: notification.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRelativeTime(notification.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.outline,
                            fontSize: 12,
                          ),
                    ),
                    if (isRecent) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(DerivedNotification n) {
    if (n.icon == Icons.description_outlined) return 'DOCUMENTO';
    if (n.icon == Icons.calendar_today) return 'EVENTO';
    return 'ALERTA';
  }
}

String _formatRelativeTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.isNegative) {
    final absDiff = timestamp.difference(DateTime.now());
    if (absDiff.inMinutes < 60) return 'em ${absDiff.inMinutes}min';
    if (absDiff.inHours < 24) return 'em ${absDiff.inHours}h';
    if (absDiff.inDays < 7) return 'em ${absDiff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  if (diff.inDays < 7) return 'há ${diff.inDays}d';
  return '${timestamp.day}/${timestamp.month}';
}
