import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../client/models/document_model.dart';
import '../providers/staff_document_provider.dart';
import 'widgets/send_document_sheet.dart';
import 'widgets/update_status_sheet.dart';

class StaffDocumentsScreen extends ConsumerWidget {
  const StaffDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffDocumentFilterProvider);
    final documentsAsync = ref.watch(staffDocumentsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              onPressed: () => showSendDocumentSheet(context, ref),
              icon: const Icon(Icons.add, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              tooltip: 'Enviar Documento',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented filter
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
                    label: 'Pendentes',
                    isSelected: filter == 'requested',
                    onTap: () => ref
                        .read(staffDocumentFilterProvider.notifier)
                        .setFilter(
                            filter == 'requested' ? null : 'requested'),
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
                final filtered = _applyFilter(documents, filter);
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
                              onTap: () => showUpdateStatusSheet(
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
    String? filter,
  ) {
    if (filter == null) return documents;
    return documents.where((d) => d.status == filter).toList();
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
                  ? Colors.amber.withValues(alpha: 0.1)
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isPending
                    ? Colors.amber.shade700
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
