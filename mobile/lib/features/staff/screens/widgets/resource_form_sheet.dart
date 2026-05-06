import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/resource_model.dart';
import '../../providers/staff_resource_provider.dart';

/// Shows the resource create/edit form bottom sheet.
/// Pass [resource] to pre-fill fields for editing; omit for creation.
void showResourceFormSheet(
  BuildContext context,
  WidgetRef ref, {
  ResourceModel? resource,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _ResourceFormSheet(resource: resource),
  );
}

class _ResourceFormSheet extends ConsumerStatefulWidget {
  final ResourceModel? resource;

  const _ResourceFormSheet({this.resource});

  @override
  ConsumerState<_ResourceFormSheet> createState() => _ResourceFormSheetState();
}

class _ResourceFormSheetState extends ConsumerState<_ResourceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late String _resourceType;
  late bool _requiresAuthorization;
  bool _isLoading = false;

  bool get _isEditing => widget.resource != null;

  static const _typeOptions = <String, String>{
    'room': 'Sala',
    'lab': 'Laboratório',
    'equipment': 'Equipamento',
    'auditorium': 'Auditório',
    'study_room': 'Sala de Estudos',
    'sports_court': 'Quadra Esportiva',
  };

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.resource?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.resource?.capacity?.toString() ?? '',
    );
    _locationController =
        TextEditingController(text: widget.resource?.location ?? '');
    _descriptionController =
        TextEditingController(text: widget.resource?.description ?? '');
    _resourceType = widget.resource?.resourceType ?? 'room';
    _requiresAuthorization =
        widget.resource?.requiresAuthorization ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(staffResourceServiceProvider);
      final capacity = _capacityController.text.isNotEmpty
          ? int.tryParse(_capacityController.text)
          : null;
      final location = _locationController.text.isNotEmpty
          ? _locationController.text
          : null;
      final description = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null;

      if (_isEditing) {
        await service.updateResource(
          widget.resource!.id,
          name: _nameController.text,
          resourceType: _resourceType,
          capacity: capacity,
          location: location,
          description: description,
          requiresAuthorization: _requiresAuthorization,
        );
      } else {
        await service.createResource(
          name: _nameController.text,
          resourceType: _resourceType,
          capacity: capacity,
          location: location,
          description: description,
          requiresAuthorization: _requiresAuthorization,
        );
      }

      ref.invalidate(staffResourcesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Recurso atualizado com sucesso!'
                  : 'Recurso criado com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao executar ação. Tente novamente.'),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Editar Recurso' : 'Novo Recurso',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Name
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: Sala 101',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome do recurso'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              // Type dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                ),
                initialValue: _resourceType,
                items: _typeOptions.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _resourceType = value);
                  }
                },
                validator: (value) =>
                    value == null ? 'Selecione o tipo' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              // Capacity
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacidade (opcional)',
                  hintText: 'Ex: 30',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Location
              TextFormField(
                controller: _locationController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Localização (opcional)',
                  hintText: 'Ex: Bloco A, 2º andar',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Detalhes sobre o recurso...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Requires authorization
              SwitchListTile(
                title: const Text('Exige Autorização do Aluno'),
                subtitle: const Text(
                  'Se ativo, reservas precisam de aprovação',
                ),
                value: _requiresAuthorization,
                onChanged: (value) {
                  setState(() => _requiresAuthorization = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                    : Text(_isEditing ? 'Salvar Alterações' : 'Criar Recurso'),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
