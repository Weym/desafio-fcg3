import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../shared/widgets/staff_search_bar.dart';
import '../models/staff_student_model.dart';
import '../providers/staff_cadastro_provider.dart';

class StaffCadastroScreen extends ConsumerWidget {
  const StaffCadastroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffCadastroFilterProvider);
    final searchQuery = ref.watch(staffCadastroSearchProvider);
    final studentsAsync = ref.watch(staffStudentsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Alunos'),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentFormSheet(context, ref),
        tooltip: 'Novo Aluno',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          StaffSearchBar(
            hintText: 'Buscar por nome, RA ou número...',
            onChanged: (query) =>
                ref.read(staffCadastroSearchProvider.notifier).setQuery(query),
          ),
          // Filter pills
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
                  Expanded(
                    child: _FilterTab(
                      label: 'Todos',
                      isSelected: filter == null,
                      onTap: () => ref
                          .read(staffCadastroFilterProvider.notifier)
                          .setFilter(null),
                    ),
                  ),
                  Expanded(
                    child: _FilterTab(
                      label: 'Ativos',
                      isSelected: filter == 'active',
                      onTap: () => ref
                          .read(staffCadastroFilterProvider.notifier)
                          .setFilter(filter == 'active' ? null : 'active'),
                    ),
                  ),
                  Expanded(
                    child: _FilterTab(
                      label: 'Inativos',
                      isSelected: filter == 'inactive',
                      onTap: () => ref
                          .read(staffCadastroFilterProvider.notifier)
                          .setFilter(filter == 'inactive' ? null : 'inactive'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Student list
          Expanded(
            child: studentsAsync.when(
              loading: () => const ResponsiveContainer(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 5, itemHeight: 88),
              ),
              error: (error, stack) => ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  onRetry: () => ref.invalidate(staffStudentsProvider),
                ),
              ),
              data: (students) {
                final filtered =
                    _applyFilters(students, filter, searchQuery);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_outline,
                    message: 'Nenhum aluno encontrado',
                  );
                }
                return Column(
                  children: [
                    if (studentsAsync.isRefreshing)
                      const LinearProgressIndicator(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(staffStudentsProvider);
                          await ref.read(staffStudentsProvider.future);
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
                            itemBuilder: (context, index) => _StudentCard(
                              student: filtered[index],
                              onEdit: () => _showStudentFormSheet(
                                context,
                                ref,
                                student: filtered[index],
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

  List<StaffStudentModel> _applyFilters(
    List<StaffStudentModel> students,
    String? statusFilter,
    String searchQuery,
  ) {
    var result = students;

    // Status filter
    if (statusFilter == 'active') {
      result = result.where((s) => s.isActive).toList();
    } else if (statusFilter == 'inactive') {
      result = result.where((s) => !s.isActive).toList();
    }

    // Search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((s) {
        final nameMatch = s.name.toLowerCase().contains(query);
        final raMatch = s.ra?.toLowerCase().contains(query) ?? false;
        final phoneMatch = s.phone?.toLowerCase().contains(query) ?? false;
        return nameMatch || raMatch || phoneMatch;
      }).toList();
    }

    return result;
  }

  void _showStudentFormSheet(
    BuildContext context,
    WidgetRef ref, {
    StaffStudentModel? student,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _StudentFormSheet(
        student: student,
        onSubmit: (data) async {
          final service = ref.read(staffCadastroServiceProvider);
          if (student != null) {
            await service.updateStudent(student.id, data);
          } else {
            await service.createStudent(data);
          }
          ref.invalidate(staffStudentsProvider);
        },
      ),
    );
  }
}

// --- Filter Tab ---

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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    );
  }
}

// --- Student Card ---

class _StudentCard extends ConsumerWidget {
  final StaffStudentModel student;
  final VoidCallback onEdit;

  const _StudentCard({
    required this.student,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: student.isActive
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.red.withValues(alpha: 0.15),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: student.isActive ? Colors.green : Colors.red,
              ),
            ),
          ),
          title: Text(
            student.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'RA: ${student.ra ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: student.isActive ? Colors.green : Colors.red,
                ),
              ),
              // Popup menu
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, ref, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                        student.isActive ? 'Desativar' : 'Ativar'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Excluir',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'Email', value: student.email),
                  if (student.phone != null && student.phone!.isNotEmpty)
                    _DetailRow(label: 'Telefone', value: student.phone!),
                  if (student.ra != null && student.ra!.isNotEmpty)
                    _DetailRow(label: 'RA', value: student.ra!),
                  if (student.semester != null)
                    _DetailRow(label: 'Período', value: '${student.semester}º'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) {
    switch (action) {
      case 'edit':
        onEdit();
      case 'toggle':
        _handleToggle(context, ref);
      case 'delete':
        _handleDelete(context, ref);
    }
  }

  Future<void> _handleToggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(staffCadastroServiceProvider)
          .toggleStatus(student.id, !student.isActive);
      ref.invalidate(staffStudentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(student.isActive
                ? 'Aluno desativado'
                : 'Aluno ativado'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Aluno'),
        content: Text(
            'Tem certeza que deseja excluir "${student.name}"? O aluno será desativado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(staffCadastroServiceProvider)
            .deleteStudent(student.id);
        ref.invalidate(staffStudentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aluno excluído')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir aluno: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

// --- Detail Row ---

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Student Form Bottom Sheet ---

class _StudentFormSheet extends StatefulWidget {
  final StaffStudentModel? student;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _StudentFormSheet({this.student, required this.onSubmit});

  @override
  State<_StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends State<_StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _raCtrl;
  late final TextEditingController _periodCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.student?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.student?.phone ?? '');
    _raCtrl = TextEditingController(text: widget.student?.ra ?? '');
    _periodCtrl = TextEditingController(text: widget.student?.semester?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _raCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };
      if (_phoneCtrl.text.trim().isNotEmpty) {
        data['phone'] = _phoneCtrl.text.trim();
      }
      if (_raCtrl.text.trim().isNotEmpty) {
        data['registration_number'] = _raCtrl.text.trim();
      }
      if (_periodCtrl.text.trim().isNotEmpty) {
        data['semester'] = int.tryParse(_periodCtrl.text.trim());
      }
      await widget.onSubmit(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'Editar Aluno' : 'Novo Aluno',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Nome *',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nome é obrigatório'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email é obrigatório';
                            }
                            if (!v.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Celular',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _raCtrl,
                          label: 'RA',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _periodCtrl,
                          label: 'Período',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(isEdit ? 'Salvar' : 'Criar Aluno'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
