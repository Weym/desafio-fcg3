import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../client/models/document_model.dart';
import '../providers/staff_document_provider.dart';
import 'widgets/send_document_sheet.dart';
import 'widgets/update_status_sheet.dart';

class StaffDocumentsScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const StaffDocumentsScreen({super.key, this.initialFilter});

  @override
  ConsumerState<StaffDocumentsScreen> createState() =>
      _StaffDocumentsScreenState();
}

class _StaffDocumentsScreenState extends ConsumerState<StaffDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    // Apply filter synchronously from constructor param — no GoRouterState race condition
    if (widget.initialFilter == 'pendentes') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(staffDocumentFilterProvider.notifier).setFilter('processing');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(staffDocumentFilterProvider);
    final typeFilter = ref.watch(staffDocumentTypeFilterProvider);
    final documentsAsync = ref.watch(staffDocumentsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: widget.initialFilter == 'pendentes'
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Documentos'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Pendentes', style: TextStyle(fontSize: 12, color: colors.primary)),
                ),
              ])
            : const Text('Documentos'),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSendDocumentSheet(context, ref),
        tooltip: 'Enviar Documento',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Status filter tabs
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
                    isSelected: filter == null,
                    onTap: () => ref
                        .read(staffDocumentFilterProvider.notifier)
                        .setFilter(null),
                  ),
                  _FilterTab(
                    label: 'Processando',
                    isSelected: filter == 'processing',
                    onTap: () => ref
                        .read(staffDocumentFilterProvider.notifier)
                        .setFilter(
                            filter == 'processing' ? null : 'processing'),
                  ),
                  _FilterTab(
                    label: 'Prontos',
                    isSelected: filter == 'ready',
                    onTap: () => ref
                        .read(staffDocumentFilterProvider.notifier)
                        .setFilter(filter == 'ready' ? null : 'ready'),
                  ),
                ],
              ),
            ),
          ),
          // Type filter pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _TypePill(
                    label: 'Todos',
                    isSelected: typeFilter == null,
                    onTap: () => ref
                        .read(staffDocumentTypeFilterProvider.notifier)
                        .setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'Histórico',
                    isSelected: typeFilter == 'transcript',
                    onTap: () => ref
                        .read(staffDocumentTypeFilterProvider.notifier)
                        .setFilter(typeFilter == 'transcript'
                            ? null
                            : 'transcript'),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'Declaração',
                    isSelected: typeFilter == 'declaration',
                    onTap: () => ref
                        .read(staffDocumentTypeFilterProvider.notifier)
                        .setFilter(typeFilter == 'declaration'
                            ? null
                            : 'declaration'),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'Atestado',
                    isSelected: typeFilter == 'enrollment_proof',
                    onTap: () => ref
                        .read(staffDocumentTypeFilterProvider.notifier)
                        .setFilter(typeFilter == 'enrollment_proof'
                            ? null
                            : 'enrollment_proof'),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'Diploma',
                    isSelected: typeFilter == 'certificate',
                    onTap: () => ref
                        .read(staffDocumentTypeFilterProvider.notifier)
                        .setFilter(typeFilter == 'certificate'
                            ? null
                            : 'certificate'),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'Outros',
                    isSelected: typeFilter == 'other',
                    onTap: () => ref
                        .read(staffDocumentTypeFilterProvider.notifier)
                        .setFilter(
                            typeFilter == 'other' ? null : 'other'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: documentsAsync.when(
              loading: () => const ResponsiveContainer(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 5, itemHeight: 72),
              ),
              error: (error, stack) => ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  onRetry: () => ref.invalidate(staffDocumentsProvider),
                ),
              ),
              data: (documents) {
                final filtered = _applyFilter(documents, filter, typeFilter);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.folder_open,
                    message: 'Nenhum documento disponível',
                  );
                }
                return Column(
                  children: [
                    if (documentsAsync.isRefreshing)
                      const LinearProgressIndicator(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(staffDocumentsProvider);
                          await ref.read(staffDocumentsProvider.future);
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
                            itemBuilder: (context, index) =>
                                _StaffDocumentCard(
                              document: filtered[index],
                              onTap: () => _showStaffDocumentDetailSheet(
                                  context, ref, filtered[index]),
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

  List<DocumentModel> _applyFilter(
    List<DocumentModel> documents,
    String? statusFilter,
    String? typeFilter,
  ) {
    var result = documents;
    if (statusFilter != null) {
      result = result.where((d) => d.status == statusFilter).toList();
    }
    if (typeFilter != null) {
      if (typeFilter == 'other') {
        final knownTypes = [
          'transcript',
          'enrollment_proof',
          'declaration',
          'certificate'
        ];
        result = result.where((d) => !knownTypes.contains(d.type)).toList();
      } else {
        result = result.where((d) => d.type == typeFilter).toList();
      }
    }
    return result;
  }
}

/// Shows full document detail in a bottom sheet for staff.
void _showStaffDocumentDetailSheet(
    BuildContext context, WidgetRef ref, DocumentModel document) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _StaffDocumentDetailContent(document: document, ref: ref),
  );
}

class _StaffDocumentDetailContent extends StatelessWidget {
  final DocumentModel document;
  final WidgetRef ref;

  const _StaffDocumentDetailContent({
    required this.document,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isProcessing = document.status == 'processing' ||
        document.status == 'requested';

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
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child:
                    Icon(Icons.description, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _typeLabel(document.type),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detail rows
          _DetailRow(label: 'Tipo', value: _typeLabel(document.type)),
          _DetailRow(
            label: 'Status',
            value: _statusLabel(document.status),
          ),
          _DetailRow(
            label: 'Data solicitação',
            value: _formatDateTime(document.requestedAt),
          ),
          if (document.completedAt != null)
            _DetailRow(
              label: 'Concluído em',
              value: _formatDateTime(document.completedAt!),
            ),
          if (document.notes != null && document.notes!.isNotEmpty)
            _DetailRow(label: 'Observações', value: document.notes!),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Atualizar Status'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showUpdateStatusSheet(context, ref, document);
                  },
                ),
              ),
              if (isProcessing) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Enviar Arquivo'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showUpdateStatusSheet(context, ref, document);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

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
            width: 130,
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

class _TypePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypePill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.3)
                : colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
        ),
      ),
    );
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
                  color:
                      isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}

String _typeLabel(String type) => switch (type) {
      'transcript' => 'Histórico Escolar',
      'enrollment_proof' => 'Comprovante de Matrícula',
      'declaration' => 'Declaração',
      'certificate' => 'Certificado',
      _ => type,
    };

String _statusLabel(String status) => switch (status) {
      'requested' => 'Solicitado',
      'processing' => 'Processando',
      'ready' => 'Pronto',
      'delivered' => 'Entregue',
      _ => status,
    };

class _StaffDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const _StaffDocumentCard({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReady = document.status == 'ready';
    final isPending =
        document.status == 'requested' || document.status == 'processing';

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              Icons.description,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(document.type),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Solicitado em ${_formatDate(document.requestedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1)
                  : isReady
                      ? colors.tertiaryContainer.withValues(alpha: 0.1)
                      : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isPending
                    ? Colors.amber.withValues(alpha: 0.2)
                    : isReady
                        ? colors.tertiary.withValues(alpha: 0.2)
                        : colors.outlineVariant,
              ),
            ),
            child: Text(
              _statusLabel(document.status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isPending
                    ? (isDark ? Colors.amber.shade300 : Colors.amber.shade700)
                    : isReady
                        ? colors.tertiary
                        : colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
