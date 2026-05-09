import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/staff_member_model.dart';
import '../providers/staff_management_provider.dart';

/// Full-screen form for staff create/edit (D-28, D-29).
/// If [member] is null → create mode. If provided → edit mode.
class StaffMemberFormScreen extends ConsumerStatefulWidget {
  final StaffMemberModel? member;
  const StaffMemberFormScreen({super.key, this.member});

  @override
  ConsumerState<StaffMemberFormScreen> createState() =>
      _StaffMemberFormScreenState();
}

class _StaffMemberFormScreenState extends ConsumerState<StaffMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _positionController;
  late final TextEditingController _workScheduleController;
  String _selectedRole = 'staff';
  bool _isLoading = false;

  bool get _isEditMode => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _nameController = TextEditingController(text: member?.name ?? '');
    _emailController = TextEditingController(text: member?.email ?? '');
    _phoneController = TextEditingController(text: member?.phone ?? '');
    _positionController = TextEditingController(text: member?.position ?? '');
    _workScheduleController =
        TextEditingController(text: member?.workSchedule ?? '');
    _selectedRole = member?.role ?? 'staff';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _workScheduleController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
    };

    // Include optional fields only if non-empty
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) data['phone'] = phone;

    final position = _positionController.text.trim();
    if (position.isNotEmpty) data['position'] = position;

    final workSchedule = _workScheduleController.text.trim();
    if (workSchedule.isNotEmpty) data['work_schedule'] = workSchedule;

    try {
      if (_isEditMode) {
        await ref
            .read(staffMemberListProvider.notifier)
            .updateMember(widget.member!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff atualizado com sucesso')),
          );
        }
      } else {
        await ref.read(staffMemberListProvider.notifier).createMember(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff criado com sucesso')),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      if (mounted) {
        final statusCode = e.response?.statusCode;
        String message;
        if (statusCode == 409) {
          message = 'Email já está em uso';
        } else if (statusCode == 403) {
          message = 'Sem permissão para esta ação';
        } else {
          message = 'Erro ao salvar. Tente novamente.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Staff' : 'Novo Staff'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _onSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Salvar',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email é obrigatório';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),

              // Position field
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Cargo / Função',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),

              // Work schedule field
              TextFormField(
                controller: _workScheduleController,
                decoration: const InputDecoration(
                  labelText: 'Horário de trabalho',
                  prefixIcon: Icon(Icons.schedule_outlined),
                  hintText: 'Ex: 08:00-17:00 Seg-Sex',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Role dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Função (Role) *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(
                      value: 'coordinator', child: Text('Coordenador')),
                  DropdownMenuItem(
                      value: 'secretary', child: Text('Secretário')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione uma função';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button (alternative to AppBar action for mobile UX)
              FilledButton.icon(
                onPressed: _isLoading ? null : _onSave,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditMode ? 'Atualizar Staff' : 'Criar Staff'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
