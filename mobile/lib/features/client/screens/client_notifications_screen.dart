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
import 'widgets/appointment_detail_sheet.dart';

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
    final filter = ref.watch(notificationFilterNotifierProvider);
    final readIds = ref.watch(readNotificationIdsProvider);
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

            final unreadCount =
                notifications.where((n) => !readIds.contains(n.id)).length;

            final filtered = switch (filter) {
              NotificationFilter.all => notifications,
              NotificationFilter.unread =>
                notifications.where((n) => !readIds.contains(n.id)).toList(),
              NotificationFilter.read =>
                notifications.where((n) => readIds.contains(n.id)).toList(),
            };

            return Column(
              children: [
                if (notificationsAsync.isRefreshing)
                  const LinearProgressIndicator(),
                // Filter tabs
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: AppSpacing.sm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Row(
                      children: [
                        _FilterTab(
                          label: 'Todas',
                          isSelected: filter == NotificationFilter.all,
                          onTap: () => ref
                              .read(
                                  notificationFilterNotifierProvider.notifier)
                              .setFilter(NotificationFilter.all),
                        ),
                        _FilterTab(
                          label: 'Não lidas',
                          isSelected: filter == NotificationFilter.unread,
                          onTap: () => ref
                              .read(
                                  notificationFilterNotifierProvider.notifier)
                              .setFilter(NotificationFilter.unread),
                        ),
                        _FilterTab(
                          label: 'Lidas',
                          isSelected: filter == NotificationFilter.read,
                          onTap: () => ref
                              .read(
                                  notificationFilterNotifierProvider.notifier)
                              .setFilter(NotificationFilter.read),
                        ),
                      ],
                    ),
                  ),
                ),
                // Header with unread count and "Visualizar todos" button
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, AppSpacing.xs, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$unreadCount não lidas',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      TextButton(
                        onPressed: unreadCount > 0
                            ? () {
                                final allIds = notifications
                                    .map((n) => n.id)
                                    .toList();
                                ref
                                    .read(
                                        readNotificationIdsProvider.notifier)
                                    .markAllAsRead(allIds);
                              }
                            : null,
                        child: const Text('Visualizar todos'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            AppEmptyState(
                              icon: Icons.notifications_none,
                              message: 'Nenhuma notificação neste filtro',
                            ),
                          ],
                        )
                      : ResponsiveContainer(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: AppSpacing.md,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final notification = filtered[index];
                              return _NotificationCard(
                                notification: notification,
                                isRead: readIds.contains(notification.id),
                                onTap: () => ref
                                    .read(readNotificationIdsProvider
                                        .notifier)
                                    .markAsRead(notification.id),
                                onDetailTap: notification.type ==
                                        NotificationType.appointmentReminder
                                    ? () {
                                        final appointments = ref
                                                .read(appointmentsProvider)
                                                .valueOrNull ??
                                            [];
                                        final aptId = notification.id
                                            .replaceFirst('apt-', '');
                                        final apt = appointments
                                            .where((a) => a.id == aptId)
                                            .firstOrNull;
                                        if (apt != null) {
                                          showAppointmentDetailSheet(
                                              context, apt);
                                        }
                                      }
                                    : null,
                              );
                            },
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
}

class _NotificationCard extends StatelessWidget {
  final DerivedNotification notification;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback? onDetailTap;

  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isRead ? 0.6 : 1.0,
      child: GlassCard(
        onTap: () {
          onTap();
          if (onDetailTap != null) onDetailTap!();
        },
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
                          color:
                              notification.color.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          _categoryLabel(notification),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colors.outline,
                              fontSize: 12,
                            ),
                      ),
                      if (!isRead) ...[
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
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.subtitle,
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }

  String _categoryLabel(DerivedNotification n) {
    if (n.icon == Icons.description_outlined) return 'DOCUMENTO';
    if (n.icon == Icons.calendar_today) return 'EVENTO';
    return 'ALERTA';
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
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
