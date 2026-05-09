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
    final colors = Theme.of(context).colorScheme;

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
              // Nome do aluno
              _DetailRow(
                label: 'Nome',
                value: appointment.studentName ?? 'Não informado',
              ),
              const SizedBox(height: 16),
              // RA
              _DetailRow(
                label: 'RA',
                value: appointment.studentRa ?? 'Não informado',
              ),
              const SizedBox(height: 16),
              // Data de emissão / criação
              _DetailRow(
                label: 'Data de emissão',
                value: _formatDate(appointment.createdAt),
              ),
              const SizedBox(height: 16),
              // Recurso
              _DetailRow(
                label: 'Recurso',
                value: appointment.resourceName ?? 'Não definido',
              ),
              const SizedBox(height: 16),
              // Status (colored badge)
              Row(
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Motivo
              _DetailRow(
                label: 'Motivo',
                value: appointment.reason,
              ),
              const SizedBox(height: 32),
              // Action buttons
              if (appointment.isUpcoming)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelAction(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(color: colors.error),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmAction(context, ref),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Confirmar'),
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
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(staffScheduleServiceProvider)
            .confirmAppointment(appointment.id);
        ref.invalidate(staffAppointmentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento confirmado')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao confirmar: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
          'Tem certeza que deseja cancelar este agendamento? O aluno será notificado.',
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
      try {
        await ref
            .read(staffScheduleServiceProvider)
            .cancelAppointment(appointment.id);
        ref.invalidate(staffAppointmentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento cancelado')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

Color _statusBackgroundColor(String status, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    'scheduled' => isDark
        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
        : Colors.green.shade100,
    'cancelled' => isDark
        ? colors.error.withValues(alpha: 0.15)
        : Colors.red.shade100,
    'completed' || 'no_show' => isDark
        ? colors.surfaceContainerHigh
        : Colors.grey.shade200,
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
      'completed' => 'Concluído',
      'no_show' => 'Ausente',
      _ => status,
    };
