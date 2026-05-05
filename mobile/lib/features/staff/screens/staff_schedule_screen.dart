import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../client/models/appointment_model.dart';
import '../providers/staff_schedule_provider.dart';
import 'widgets/create_slot_sheet.dart';

class StaffScheduleScreen extends ConsumerWidget {
  const StaffScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffScheduleFilterProvider);
    final appointmentsAsync = ref.watch(staffAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateSlotSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo Slot'),
      ),
      body: Column(
        children: [
          // Filter chips row (D-06, D-09)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: filter == null,
                  onSelected: (_) => ref
                      .read(staffScheduleFilterProvider.notifier)
                      .setFilter(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Agendados'),
                  selected: filter == 'scheduled',
                  onSelected: (_) => ref
                      .read(staffScheduleFilterProvider.notifier)
                      .setFilter(
                          filter == 'scheduled' ? null : 'scheduled'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Cancelados'),
                  selected: filter == 'cancelled',
                  onSelected: (_) => ref
                      .read(staffScheduleFilterProvider.notifier)
                      .setFilter(
                          filter == 'cancelled' ? null : 'cancelled'),
                ),
              ],
            ),
          ),
          // Appointment list
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text('Erro ao carregar agendamentos'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(staffAppointmentsProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (appointments) {
                final filtered = _applyFilter(appointments, filter);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum agendamento encontrado',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(staffAppointmentsProvider);
                    await ref.read(staffAppointmentsProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _AppointmentCard(
                      appointment: filtered[index],
                      onTap: () => context.push(
                        '/staff/schedule/${filtered[index].id}',
                        extra: filtered[index],
                      ),
                    ),
                  ),
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

Color _statusBackgroundColor(String status) => switch (status) {
      'scheduled' => Colors.green.shade100,
      'cancelled' => Colors.red.shade100,
      'completed' || 'no_show' => Colors.grey.shade200,
      _ => Colors.grey.shade200,
    };

Color _statusTextColor(String status) => switch (status) {
      'scheduled' => Colors.green.shade800,
      'cancelled' => Colors.red.shade800,
      'completed' || 'no_show' => Colors.grey.shade700,
      _ => Colors.grey.shade700,
    };

String _statusLabel(String status) => switch (status) {
      'scheduled' => 'Agendado',
      'cancelled' => 'Cancelado',
      'completed' => 'Concluido',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              // Middle content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.reason,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildDateTimeText(),
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing status chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor(appointment.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(appointment.status),
                  style: TextStyle(
                    color: _statusTextColor(appointment.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDateTimeText() {
    final parts = <String>[];
    if (appointment.date != null) parts.add(appointment.date!);
    if (appointment.startTime != null) parts.add(appointment.startTime!);
    return parts.isEmpty ? 'Data nao definida' : parts.join(' ');
  }
}
