import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../models/resource_model.dart';
import '../models/appointment_model.dart';
import '../providers/resource_booking_provider.dart';
import '../providers/appointment_provider.dart';
import 'widgets/booking_flow_sheet.dart';

class ClientResourcesScreen extends ConsumerWidget {
  const ClientResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recursos'),
          actions: const [AppBarActions()],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Disponíveis'),
              Tab(text: 'Meus Agendamentos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AvailableResourcesTab(),
            _MyAppointmentsTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Available Resources
// ─────────────────────────────────────────────────────────────────────────────

class _AvailableResourcesTab extends ConsumerWidget {
  const _AvailableResourcesTab();

  static const _filterOptions = <String?, String>{
    null: 'Todos',
    'room': 'Sala',
    'lab': 'Lab',
    'equipment': 'Equip.',
    'auditorium': 'Auditório',
    'study_room': 'S. Estudos',
    'sports_court': 'Quadra',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(resourceTypeFilterProvider);
    final resourcesAsync = ref.watch(availableResourcesProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Segmented filter
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.entries.map((entry) {
                  final isSelected = filter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(resourceTypeFilterProvider.notifier)
                          .setFilter(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        colors.primary.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          entry.value,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        // Resource list
        Expanded(
          child: resourcesAsync.when(
            loading: () => const ResponsiveContainer(
              padding: EdgeInsets.all(16),
              child: AppSkeletonList(itemCount: 5, itemHeight: 88),
            ),
            error: (error, stack) => ResponsiveContainer(
              padding: const EdgeInsets.all(16),
              child: AppErrorState(
                onRetry: () => ref.invalidate(availableResourcesProvider),
              ),
            ),
            data: (resources) {
              if (resources.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.meeting_room_outlined,
                  message: 'Nenhum recurso disponível',
                );
              }
              return Column(
                children: [
                  if (resourcesAsync.isRefreshing)
                    const LinearProgressIndicator(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(availableResourcesProvider);
                        await ref.read(availableResourcesProvider.future);
                      },
                      child: ResponsiveContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: AppSpacing.sm,
                        ),
                        child: ListView.separated(
                          itemCount: resources.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) => _ResourceCard(
                            resource: resources[index],
                            onTap: () => showBookingFlowSheet(
                              context,
                              ref,
                              resources[index],
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
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final ClientResourceModel resource;
  final VoidCallback onTap;

  const _ResourceCard({required this.resource, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Resource icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              resource.typeIcon,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(resource),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                if (resource.requiresAuthorization) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: 12,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Requer Autorização',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Chevron
          Icon(
            Icons.chevron_right,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _subtitle(ClientResourceModel resource) {
    final parts = <String>[resource.typeLabel];
    if (resource.capacity != null) parts.add('${resource.capacity} lugares');
    if (resource.location != null) parts.add(resource.location!);
    return parts.join(' · ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: My Appointments
// ─────────────────────────────────────────────────────────────────────────────

class _MyAppointmentsTab extends ConsumerWidget {
  const _MyAppointmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return appointmentsAsync.when(
      loading: () => const ResponsiveContainer(
        padding: EdgeInsets.all(16),
        child: AppSkeletonList(itemCount: 4, itemHeight: 80),
      ),
      error: (error, stack) => ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        child: AppErrorState(
          onRetry: () => ref.invalidate(appointmentsProvider),
        ),
      ),
      data: (appointments) {
        if (appointments.isEmpty) {
          return const AppEmptyState(
            icon: Icons.event_busy,
            message: 'Nenhum agendamento encontrado',
          );
        }
        return Column(
          children: [
            if (appointmentsAsync.isRefreshing)
              const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(appointmentsProvider);
                  await ref.read(appointmentsProvider.future);
                },
                child: ResponsiveContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: AppSpacing.sm,
                  ),
                  child: ListView.separated(
                    itemCount: appointments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => _AppointmentCard(
                      appointment: appointments[index],
                      onCancel: appointments[index].isUpcoming
                          ? () => _confirmCancel(context, ref, appointments[index])
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    AppointmentModel appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancelar Agendamento'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final service = ref.read(appointmentServiceProvider);
      await service.cancelAppointment(appointment.id);
      ref.invalidate(appointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento cancelado com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cancelar agendamento. Tente novamente.'),
          ),
        );
      }
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onCancel;

  const _AppointmentCard({required this.appointment, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Calendar icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              Icons.event,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
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
                const SizedBox(height: 2),
                Text(
                  _formatSlotInfo(appointment),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Status + Cancel
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: appointment.status),
              if (onCancel != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onCancel,
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatSlotInfo(AppointmentModel appt) {
    final parts = <String>[];
    if (appt.slotDate != null) parts.add(appt.slotDate!);
    if (appt.slotStartTime != null) {
      final time = appt.slotStartTime!;
      if (appt.endTime != null) {
        parts.add('$time - ${appt.endTime}');
      } else {
        parts.add(time);
      }
    }
    return parts.isEmpty ? 'Data não informada' : parts.join(' · ');
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, badgeColor) = switch (status) {
      'scheduled' => ('Agendado', colors.primary),
      'completed' => ('Concluído', colors.tertiary),
      'cancelled' => ('Cancelado', colors.error),
      'no_show' => ('Não compareceu', colors.outline),
      _ => (status, colors.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}
