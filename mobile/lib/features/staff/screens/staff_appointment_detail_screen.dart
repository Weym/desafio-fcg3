import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../client/models/appointment_model.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../providers/staff_schedule_provider.dart';

class StaffAppointmentDetailScreen extends ConsumerWidget {
  final AppointmentModel appointment;

  const StaffAppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Agendamento'),
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            _InfoRow(
              label: 'Status',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor(appointment.status, context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(appointment.status),
                  style: TextStyle(
                    color: _statusTextColor(appointment.status, context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date row
            _InfoRow(
              label: 'Data',
              child: Text(
                appointment.slotDate ?? 'Nao definida',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            // Time row
            _InfoRow(
              label: 'Horario',
              child: Text(
                _buildTimeText(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            // Reason row
            _InfoRow(
              label: 'Motivo',
              child: Text(
                appointment.reason,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons (D-07)
            if (appointment.isUpcoming)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelAction(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancelar Agendamento'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmAction(context, ref),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Confirmar Agendamento'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      ),
    );
  }

  String _buildTimeText() {
    if (appointment.slotStartTime == null && appointment.endTime == null) {
      return 'Nao definido';
    }
    final start = appointment.slotStartTime ?? '--:--';
    final end = appointment.endTime ?? '--:--';
    return '$start - $end';
  }

  Future<void> _confirmAction(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Agendamento'),
        content: const Text('Confirmar este agendamento com o aluno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Agendamento'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(staffScheduleServiceProvider)
          .confirmAppointment(appointment.id);
      ref.invalidate(staffAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento confirmado!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _cancelAction(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento? O aluno sera notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Cancelar Agendamento'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(staffScheduleServiceProvider)
          .cancelAppointment(appointment.id);
      ref.invalidate(staffAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento cancelado!')),
        );
        Navigator.pop(context);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

Color _statusBackgroundColor(String status, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    'scheduled' => isDark ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : Colors.green.shade100,
    'cancelled' => isDark ? colors.error.withValues(alpha: 0.15) : Colors.red.shade100,
    'completed' || 'no_show' => isDark ? colors.surfaceContainerHigh : Colors.grey.shade200,
    _ => isDark ? colors.surfaceContainerHigh : Colors.grey.shade200,
  };
}

Color _statusTextColor(String status, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    'scheduled' => isDark ? const Color(0xFF81C784) : Colors.green.shade800,
    'cancelled' => isDark ? colors.error : Colors.red.shade800,
    'completed' || 'no_show' => colors.onSurfaceVariant,
    _ => colors.onSurfaceVariant,
  };
}

String _statusLabel(String status) => switch (status) {
      'scheduled' => 'Agendado',
      'cancelled' => 'Cancelado',
      'completed' => 'Concluido',
      'no_show' => 'Ausente',
      _ => status,
    };
