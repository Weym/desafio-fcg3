import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/auth_state.dart';
import '../models/staff_member_model.dart';
import '../providers/staff_management_provider.dart';
import 'staff_member_form_screen.dart';

/// Management screen (6th tab). Per D-12:
/// - Provider sees TabBar: "Staff" + "Alunos"
/// - Staff sees student list placeholder directly (D-11)
class StaffGestaoScreen extends ConsumerWidget {
  const StaffGestaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isProvider =
        authState is AuthAuthenticated && authState.user.isProvider;

    if (isProvider) {
      return const _ProviderGestaoView();
    }
    return const _StaffGestaoView();
  }
}

/// Provider view: TabBar with "Staff" and "Alunos" tabs (D-12).
/// Staff tab shows full CRUD list. Alunos tab = placeholder (D-13).
class _ProviderGestaoView extends StatelessWidget {
  const _ProviderGestaoView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Staff'),
              Tab(text: 'Alunos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StaffListTab(),
            // Alunos tab — placeholder pending Phase 19 integration (D-13)
            Center(
              child: Text('Gestão de alunos será integrada em breve'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staff view: sees student list directly without TabBar (D-11).
/// Placeholder pending Phase 19 integration.
class _StaffGestaoView extends StatelessWidget {
  const _StaffGestaoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Alunos'),
      ),
      body: const Center(
        child: Text('Gestão de alunos será integrada em breve'),
      ),
    );
  }
}

/// Main staff list widget with search, filter chips, card list, and FAB.
class _StaffListTab extends ConsumerStatefulWidget {
  const _StaffListTab();

  @override
  ConsumerState<_StaffListTab> createState() => _StaffListTabState();
}

class _StaffListTabState extends ConsumerState<_StaffListTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(staffMemberListProvider.notifier)
          .setSearch(query.isEmpty ? null : query);
    });
  }

  void _onFilterSelected(String? status) {
    setState(() => _activeFilter = status);
    ref.read(staffMemberListProvider.notifier).setStatusFilter(status);
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffMemberListProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const StaffMemberFormScreen(),
          ),
        ),
        tooltip: 'Adicionar Staff',
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter chips
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
                  _FilterTab(
                    label: 'Todos',
                    isSelected: _activeFilter == null,
                    onTap: () => _onFilterSelected(null),
                  ),
                  _FilterTab(
                    label: 'Ativos',
                    isSelected: _activeFilter == 'active',
                    onTap: () => _onFilterSelected(
                      _activeFilter == 'active' ? null : 'active',
                    ),
                  ),
                  _FilterTab(
                    label: 'Inativos',
                    isSelected: _activeFilter == 'inactive',
                    onTap: () => _onFilterSelected(
                      _activeFilter == 'inactive' ? null : 'inactive',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Staff list
          Expanded(
            child: staffAsync.when(
              loading: () => const ResponsiveContainer(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 5, itemHeight: 80),
              ),
              error: (error, stack) => ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  message: 'Erro ao carregar staff',
                  onRetry: () =>
                      ref.read(staffMemberListProvider.notifier).refresh(),
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_outline,
                    message: 'Nenhum staff encontrado',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(staffMemberListProvider.notifier).refresh(),
                  child: ResponsiveContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: AppSpacing.sm,
                    ),
                    child: ListView.separated(
                      itemCount: members.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _StaffCard(
                        member: members[index],
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
}

/// Filter tab chip widget — matches established pattern from staff_documents_screen.
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

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}

/// Card widget for a staff member in the list.
class _StaffCard extends ConsumerWidget {
  final StaffMemberModel member;

  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StaffMemberFormScreen(member: member),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Avatar circle with initial
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Center(
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name, email, position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.position != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.position!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: member.isActive
                  ? Colors.green.withValues(alpha: isDark ? 0.15 : 0.1)
                  : Colors.red.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: member.isActive
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              member.isActive ? 'Ativo' : 'Inativo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: member.isActive
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                    : (isDark ? Colors.red.shade300 : Colors.red.shade700),
              ),
            ),
          ),

          // Popup menu
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: member.isActive ? 'deactivate' : 'reactivate',
                child: Row(
                  children: [
                    Icon(
                      member.isActive
                          ? Icons.person_off
                          : Icons.person_add_alt_1,
                      size: 18,
                      color: member.isActive ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      member.isActive ? 'Desativar' : 'Reativar',
                      style: TextStyle(
                        color: member.isActive ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StaffMemberFormScreen(member: member),
          ),
        );
      case 'deactivate':
        _showConfirmDialog(
          context,
          ref,
          title: 'Desativar Staff',
          message:
              'Tem certeza que deseja desativar ${member.name}? O staff não poderá mais acessar o sistema.',
          confirmLabel: 'Desativar',
          isDestructive: true,
          onConfirm: () => ref
              .read(staffMemberListProvider.notifier)
              .deleteMember(member.id),
        );
      case 'reactivate':
        _showConfirmDialog(
          context,
          ref,
          title: 'Reativar Staff',
          message:
              'Deseja reativar ${member.name}? O staff voltará a ter acesso ao sistema.',
          confirmLabel: 'Reativar',
          isDestructive: false,
          onConfirm: () => ref
              .read(staffMemberListProvider.notifier)
              .updateMember(member.id, {'status': 'active'}),
        );
    }
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await onConfirm();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$confirmLabel realizado com sucesso')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao realizar ação')),
                  );
                }
              }
            },
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
