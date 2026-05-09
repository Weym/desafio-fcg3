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
import '../../../shared/widgets/staff_search_bar.dart';
import '../../client/models/appointment_model.dart';
import '../providers/staff_schedule_provider.dart';
import 'widgets/create_slot_sheet.dart';

class StaffScheduleScreen extends ConsumerWidget {
  const StaffScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffScheduleFilterProvider);
    final searchQuery = ref.watch(staffScheduleSearchProvider);
    final appointmentsAsync = ref.watch(staffAppointmentsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateSlotSheet(context, ref),
        tooltip: 'Novo Slot',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar above filter tabs
          StaffSearchBar(
            hintText: 'Buscar por nome ou RA...',
            onChanged: (q) => ref
                .read(staffScheduleSearchProvider.notifier)
                .setQuery(q),
          ),
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
                final filtered = _applyFilter(appointments, filter, searchQuery);
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
    String searchQuery,
  ) {
    var result = appointments;

    // Apply status filter
    if (filter != null) {
      result = result.where((a) => a.status == filter).toList();
    }

    // Apply search query (client-side, by name or RA)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((a) {
        final nameMatch =
            a.studentName?.toLowerCase().contains(query) ?? false;
        final raMatch = a.studentRa?.contains(query) ?? false;
        return nameMatch || raMatch;
      }).toList();
    }

    return result;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isScheduled = appointment.status == 'scheduled';

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.primaryContainer,
            child: Text(
              appointment.studentName?[0].toUpperCase() ?? '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.studentName ?? 'Aluno',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.resourceName ?? 'Recurso não definido',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _buildDateTimeText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isScheduled
                  ? (isDark ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : const Color(0xFF4CAF50).withValues(alpha: 0.1))
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isScheduled
                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
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
    if (appointment.slotDate != null) parts.add(appointment.slotDate!);
    if (appointment.slotStartTime != null) parts.add(appointment.slotStartTime!);
    return parts.isEmpty ? 'Data não definida' : parts.join(' ');
  }
}
