import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../client/models/appointment_model.dart';
import '../providers/staff_schedule_provider.dart';
import 'widgets/create_slot_sheet.dart';

class StaffScheduleScreen extends ConsumerWidget {
  const StaffScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffScheduleFilterProvider);
    final appointmentsAsync = ref.watch(staffAppointmentsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton.filled(
            onPressed: () => showCreateSlotSheet(context, ref),
            icon: const Icon(Icons.add, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            tooltip: 'Novo Slot',
          ),
          const AppBarActions(),
        ],
      ),
      body: Column(
        children: [
          // Segmented filter
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: AppSpacing.sm,
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'Todos',
                    isSelected: filter == null,
                    onTap: () => ref
                        .read(staffScheduleFilterProvider.notifier)
                        .setFilter(null),
                  ),
                  _FilterTab(
                    label: 'Agendados',
                    isSelected: filter == 'scheduled',
                    onTap: () => ref
                        .read(staffScheduleFilterProvider.notifier)
                        .setFilter(
                            filter == 'scheduled' ? null : 'scheduled'),
                  ),
                  _FilterTab(
                    label: 'Cancelados',
                    isSelected: filter == 'cancelled',
                    onTap: () => ref
                        .read(staffScheduleFilterProvider.notifier)
                        .setFilter(
                            filter == 'cancelled' ? null : 'cancelled'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const ResponsiveContainer(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 5, itemHeight: 72),
              ),
              error: (error, stack) => ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  onRetry: () => ref.invalidate(staffAppointmentsProvider),
                ),
              ),
              data: (appointments) {
                final filtered = _applyFilter(appointments, filter);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.calendar_today,
                    message: 'Nenhum agendamento',
                  );
                }
                return Column(
                  children: [
                    if (appointmentsAsync.isRefreshing)
                      const LinearProgressIndicator(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(staffAppointmentsProvider);
                          await ref.read(staffAppointmentsProvider.future);
                        },
                        child: ResponsiveContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: AppSpacing.sm,
                          ),
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) =>
                                _AppointmentCard(
                              appointment: filtered[index],
                              onTap: () => context.push(
                                '/staff/schedule/${filtered[index].id}',
                                extra: filtered[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppointmentModel> _applyFilter(
    List<AppointmentModel> appointments,
    String? filter,
  ) {
    if (filter == null) return appointments;
    return appointments.where((a) => a.status == filter).toList();
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

String _statusLabel(String status) => switch (status) {
      'scheduled' => 'Agendado',
      'cancelled' => 'Cancelado',
      'completed' => 'Concluído',
      'no_show' => 'Ausente',
      _ => status,
    };

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isScheduled = appointment.status == 'scheduled';

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              Icons.calendar_today,
              color: colors.tertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.reason,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _buildDateTimeText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isScheduled
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isScheduled
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                    : colors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _statusLabel(appointment.status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isScheduled
                    ? const Color(0xFF2E7D32)
                    : colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDateTimeText() {
    final parts = <String>[];
    if (appointment.date != null) parts.add(appointment.date!);
    if (appointment.startTime != null) parts.add(appointment.startTime!);
    return parts.isEmpty ? 'Data não definida' : parts.join(' ');
  }
}
