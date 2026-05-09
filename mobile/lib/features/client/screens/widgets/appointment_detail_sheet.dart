import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/appointment_model.dart';

/// Shows a bottom sheet with full appointment details.
void showAppointmentDetailSheet(
    BuildContext context, AppointmentModel appointment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _AppointmentDetailSheet(appointment: appointment),
  );
}

class _AppointmentDetailSheet extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentDetailSheet({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Icon(Icons.calendar_today,
                    color: colors.onSecondaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Detalhes do Agendamento',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(appointment.status, colors)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: _statusColor(appointment.status, colors)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _statusLabel(appointment.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _statusColor(appointment.status, colors),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detail rows
          _DetailRow(label: 'Motivo', value: appointment.reason),
          if (appointment.slotDate != null)
            _DetailRow(label: 'Data', value: appointment.slotDate!),
          if (appointment.slotStartTime != null)
            _DetailRow(
                label: 'Horário início', value: appointment.slotStartTime!),
          if (appointment.endTime != null)
            _DetailRow(label: 'Horário fim', value: appointment.endTime!),
          _DetailRow(
              label: 'Criado em',
              value: _formatDateTime(appointment.createdAt)),
        ],
      ),
    );
  }

  Color _statusColor(String status, ColorScheme colors) => switch (status) {
        'scheduled' => colors.primary,
        'completed' => colors.tertiary,
        'cancelled' => colors.error,
        'no_show' => colors.outline,
        _ => colors.onSurfaceVariant,
      };

  String _statusLabel(String status) => switch (status) {
        'scheduled' => 'Agendado',
        'completed' => 'Concluído',
        'cancelled' => 'Cancelado',
        'no_show' => 'Não compareceu',
        _ => status,
      };

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
