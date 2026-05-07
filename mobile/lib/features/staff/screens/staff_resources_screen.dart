import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../models/resource_model.dart';
import '../providers/staff_resource_provider.dart';
import 'widgets/resource_form_sheet.dart';

class StaffResourcesScreen extends ConsumerWidget {
  const StaffResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffResourceTypeFilterProvider);
    final resourcesAsync = ref.watch(staffResourcesProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos'),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showResourceFormSheet(context, ref),
        tooltip: 'Novo Recurso',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Segmented type filter
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'Todos',
                      isSelected: filter == null,
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(null),
                    ),
                    _FilterTab(
                      label: 'Sala',
                      isSelected: filter == 'room',
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(filter == 'room' ? null : 'room'),
                    ),
                    _FilterTab(
                      label: 'Lab',
                      isSelected: filter == 'lab',
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(filter == 'lab' ? null : 'lab'),
                    ),
                    _FilterTab(
                      label: 'Equip.',
                      isSelected: filter == 'equipment',
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(
                              filter == 'equipment' ? null : 'equipment'),
                    ),
                    _FilterTab(
                      label: 'Audit.',
                      isSelected: filter == 'auditorium',
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(
                              filter == 'auditorium' ? null : 'auditorium'),
                    ),
                    _FilterTab(
                      label: 'Estudos',
                      isSelected: filter == 'study_room',
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(
                              filter == 'study_room' ? null : 'study_room'),
                    ),
                    _FilterTab(
                      label: 'Quadra',
                      isSelected: filter == 'sports_court',
                      onTap: () => ref
                          .read(staffResourceTypeFilterProvider.notifier)
                          .setFilter(filter == 'sports_court'
                              ? null
                              : 'sports_court'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: resourcesAsync.when(
              loading: () => const ResponsiveContainer(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 5, itemHeight: 88),
              ),
              error: (error, stack) => ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  onRetry: () => ref.invalidate(staffResourcesProvider),
                ),
              ),
              data: (resources) {
                final filtered = _applyFilter(resources, filter);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.meeting_room,
                    message: 'Nenhum recurso encontrado',
                  );
                }
                return Column(
                  children: [
                    if (resourcesAsync.isRefreshing)
                      const LinearProgressIndicator(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(staffResourcesProvider);
                          await ref.read(staffResourcesProvider.future);
                        },
                        child: ResponsiveContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: AppSpacing.sm,
                          ),
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) =>
                                _ResourceCard(
                              resource: filtered[index],
                              onEdit: () => showResourceFormSheet(
                                context,
                                ref,
                                resource: filtered[index],
                              ),
                              onDeactivate: () =>
                                  _deactivateResource(context, ref, filtered[index]),
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

  List<ResourceModel> _applyFilter(
    List<ResourceModel> resources,
    String? filter,
  ) {
    if (filter == null) return resources;
    return resources.where((r) => r.resourceType == filter).toList();
  }

  Future<void> _deactivateResource(
    BuildContext context,
    WidgetRef ref,
    ResourceModel resource,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar Recurso'),
        content: Text('Deseja desativar "${resource.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(staffResourceServiceProvider).deleteResource(resource.id);
        ref.invalidate(staffResourcesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurso desativado com sucesso')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao desativar recurso. Tente novamente.'),
            ),
          );
        }
      }
    }
  }
}

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

class _ResourceCard extends StatelessWidget {
  final ResourceModel resource;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _ResourceCard({
    required this.resource,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              _iconForType(resource.resourceType),
              color: colors.tertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resource.name,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Availability indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: resource.isAvailable
                            ? (isDark ? const Color(0xFF81C784) : const Color(0xFF4CAF50))
                            : colors.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (resource.requiresAuthorization) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Requer Autorização',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'deactivate':
                  onDeactivate();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Editar'),
              ),
              const PopupMenuItem(
                value: 'deactivate',
                child: Text('Desativar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[resource.typeLabel];
    if (resource.capacity != null) {
      parts.add('Cap: ${resource.capacity}');
    }
    if (resource.location != null && resource.location!.isNotEmpty) {
      parts.add(resource.location!);
    }
    return parts.join(' • ');
  }

  IconData _iconForType(String type) => switch (type) {
        'room' => Icons.meeting_room,
        'lab' => Icons.science,
        'equipment' => Icons.devices,
        'auditorium' => Icons.event_seat,
        'study_room' => Icons.menu_book,
        'sports_court' => Icons.sports_basketball,
        _ => Icons.meeting_room,
      };
}
