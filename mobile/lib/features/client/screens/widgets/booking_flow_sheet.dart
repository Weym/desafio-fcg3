import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/resource_model.dart';
import '../../providers/resource_booking_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../../staff/models/scheduling_slot_model.dart';

/// Shows the booking flow bottom sheet for a given resource.
void showBookingFlowSheet(
  BuildContext context,
  WidgetRef ref,
  ClientResourceModel resource,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => _BookingFlowSheet(
        resource: resource,
        scrollController: scrollController,
      ),
    ),
  );
}

class _BookingFlowSheet extends ConsumerStatefulWidget {
  final ClientResourceModel resource;
  final ScrollController scrollController;

  const _BookingFlowSheet({
    required this.resource,
    required this.scrollController,
  });

  @override
  ConsumerState<_BookingFlowSheet> createState() => _BookingFlowSheetState();
}

class _BookingFlowSheetState extends ConsumerState<_BookingFlowSheet> {
  int _currentStep = 0; // 0 = slot selection, 1 = confirm + upload
  String? _selectedSlotId;
  SchedulingSlotModel? _selectedSlot;
  final _reasonController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String? _fileError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canProceedToStep2 => _selectedSlotId != null;

  bool get _canConfirm {
    if (_reasonController.text.trim().isEmpty) return false;
    if (widget.resource.requiresAuthorization && _selectedFile == null) {
      return false;
    }
    return true;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Validate file size (5MB max)
    if (file.size > 5 * 1024 * 1024) {
      setState(() {
        _fileError = 'Arquivo excede o limite de 5MB';
        _selectedFile = null;
      });
      return;
    }

    setState(() {
      _selectedFile = file;
      _fileError = null;
    });
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(resourceBookingServiceProvider);

      // Book the slot
      final appointment = await service.bookSlot(
        slotId: _selectedSlotId!,
        reason: _reasonController.text.trim(),
      );

      // Upload authorization file if required
      if (widget.resource.requiresAuthorization && _selectedFile != null) {
        await service.uploadAuthorization(
          appointmentId: appointment.id,
          filePath: _selectedFile!.path!,
          fileName: _selectedFile!.name,
        );
      }

      // Invalidate caches
      ref.invalidate(appointmentsProvider);
      ref.invalidate(availableResourcesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento confirmado!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao agendar: ${e.toString().contains('409') ? 'Horário já reservado' : 'Tente novamente'}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          _buildHeader(context),
          const SizedBox(height: 16),
          // Step indicator
          _buildStepIndicator(context),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _currentStep == 0
                ? _buildStep1(context)
                : _buildStep2(context),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Icon(
            widget.resource.typeIcon,
            color: colors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.resource.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                widget.resource.typeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        if (widget.resource.requiresAuthorization)
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outlined, size: 12, color: isDark ? Colors.amber.shade300 : Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Autorização',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        _StepDot(isActive: true, label: '1. Horário'),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1
                ? colors.primary
                : colors.outlineVariant,
          ),
        ),
        _StepDot(isActive: _currentStep >= 1, label: '2. Confirmar'),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    final slotsAsync = ref.watch(resourceSlotsProvider(widget.resource.id));
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: slotsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Erro ao carregar horários'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      resourceSlotsProvider(widget.resource.id),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            data: (slots) {
              final available = slots.where((s) => s.isAvailable).toList();
              if (available.isEmpty) {
                return const Center(
                  child: Text('Sem horários disponíveis para este recurso'),
                );
              }

              // Group by date
              final grouped = <String, List<SchedulingSlotModel>>{};
              for (final slot in available) {
                grouped.putIfAbsent(slot.date, () => []).add(slot);
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final date = grouped.keys.elementAt(index);
                  final dateSlots = grouped[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          _formatDateHeader(date),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dateSlots.map((slot) {
                          final isSelected = _selectedSlotId == slot.id;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedSlotId = slot.id;
                              _selectedSlot = slot;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary
                                    : colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                '${slot.startTime} - ${slot.endTime}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colors.onPrimary
                                      : colors.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Next button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canProceedToStep2
                ? () => setState(() => _currentStep = 1)
                : null,
            child: const Text('Próximo'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      controller: widget.scrollController,
      children: [
        // Summary card
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.meeting_room,
                label: widget.resource.name,
              ),
              if (_selectedSlot != null) ...[
                const SizedBox(height: 4),
                _SummaryRow(
                  icon: Icons.calendar_today,
                  label: _formatDateHeader(_selectedSlot!.date),
                ),
                const SizedBox(height: 4),
                _SummaryRow(
                  icon: Icons.schedule,
                  label:
                      '${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reason field
        TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Motivo do agendamento',
            hintText: 'Ex: Aula prática de redes',
          ),
          maxLines: 2,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Authorization upload (if required)
        if (widget.resource.requiresAuthorization) ...[
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outlined,
                          size: 18, color: isDark ? Colors.amber.shade300 : Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este recurso exige documento de autorização (PDF, JPG ou PNG, máx. 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _selectedFile != null
                            ? _selectedFile!.name
                            : 'Selecionar Arquivo',
                      ),
                    ),
                  ),
                  if (_fileError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _fileError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.error,
                      ),
                    ),
                  ],
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: colors.tertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_selectedFile!.name} (${(_selectedFile!.size / 1024).toStringAsFixed(0)} KB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.tertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Back + Confirm buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isLoading ? null : () => setState(() => _currentStep = 0),
                child: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isLoading || !_canConfirm ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateHeader(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const weekdays = [
        'Seg',
        'Ter',
        'Qua',
        'Qui',
        'Sex',
        'Sáb',
        'Dom',
      ];
      const months = [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez',
      ];
      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];
      return '$weekday, ${date.day} $month';
    } catch (_) {
      return dateStr;
    }
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final String label;

  const _StepDot({required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: isActive
              ? Icon(Icons.check, size: 14, color: colors.onPrimary)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}
