import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_schedule_provider.dart';

/// Shows the create slot bottom sheet. Called from ScheduleScreen FAB.
void showCreateSlotSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _CreateSlotSheet(),
  );
}

class _CreateSlotSheet extends ConsumerStatefulWidget {
  const _CreateSlotSheet();

  @override
  ConsumerState<_CreateSlotSheet> createState() => _CreateSlotSheetState();
}

class _CreateSlotSheetState extends ConsumerState<_CreateSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  int _slotDuration = 30;
  bool _isLoading = false;

  @override
  void dispose() {
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
        _endTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final startStr = _startTimeController.text;
      final endStr = _endTimeController.text;

      await ref.read(staffScheduleServiceProvider).createSlots(
            date: dateStr,
            startTime: startStr,
            endTime: endStr,
            slotDurationMinutes: _slotDuration,
          );
      ref.invalidate(staffSlotsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot criado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao executar acao. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Criar Slot de Disponibilidade',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Date field
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Selecione a data' : null,
            ),
            const SizedBox(height: 16),
            // Start time field
            TextFormField(
              controller: _startTimeController,
              readOnly: true,
              onTap: _pickStartTime,
              decoration: const InputDecoration(
                labelText: 'Horario de inicio',
                suffixIcon: Icon(Icons.access_time),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Selecione o horario de inicio'
                  : null,
            ),
            const SizedBox(height: 16),
            // End time field
            TextFormField(
              controller: _endTimeController,
              readOnly: true,
              onTap: _pickEndTime,
              decoration: const InputDecoration(
                labelText: 'Horario de termino',
                suffixIcon: Icon(Icons.access_time),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Selecione o horario de termino'
                  : null,
            ),
            const SizedBox(height: 16),
            // Duration dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Duracao do slot (minutos)',
              ),
              initialValue: _slotDuration,
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 minutos')),
                DropdownMenuItem(value: 30, child: Text('30 minutos')),
                DropdownMenuItem(value: 45, child: Text('45 minutos')),
                DropdownMenuItem(value: 60, child: Text('60 minutos')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _slotDuration = value);
                }
              },
            ),
            const SizedBox(height: 24),
            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar Slot'),
            ),
          ],
        ),
      ),
    );
  }
}
