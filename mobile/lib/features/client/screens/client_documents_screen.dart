import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../models/document_model.dart';
import '../providers/document_provider.dart';
import 'widgets/document_request_sheet.dart';

class ClientDocumentsScreen extends ConsumerWidget {
  const ClientDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(documentFilterProvider);
    final documentsAsync = ref.watch(documentsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDocumentRequestSheet(context, ref),
        tooltip: 'Solicitar Documento',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Segmented filter control
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
                    label: 'Ver todos',
                    isSelected: filter == null,
                    onTap: () => ref
                        .read(documentFilterProvider.notifier)
                        .setFilter(null),
                  ),
                  _FilterTab(
                    label: 'Pendentes',
                    isSelected: filter == 'pending',
                    onTap: () => ref
                        .read(documentFilterProvider.notifier)
                        .setFilter(filter == 'pending' ? null : 'pending'),
                  ),
                  _FilterTab(
                    label: 'Prontos',
                    isSelected: filter == 'ready',
                    onTap: () => ref
                        .read(documentFilterProvider.notifier)
                        .setFilter(filter == 'ready' ? null : 'ready'),
                  ),
                ],
              ),
            ),
          ),
          // Document list
          Expanded(
            child: documentsAsync.when(
              loading: () => const ResponsiveContainer(
                padding: EdgeInsets.all(16),
                child: AppSkeletonList(itemCount: 5, itemHeight: 72),
              ),
              error: (error, stack) => ResponsiveContainer(
                padding: const EdgeInsets.all(16),
                child: AppErrorState(
                  onRetry: () => ref.invalidate(documentsProvider),
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
                          ref.invalidate(documentsProvider);
                          await ref.read(documentsProvider.future);
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
                            itemBuilder: (context, index) => _DocumentCard(
                              document: filtered[index],
                              onDownload:
                                  filtered[index].isDownloadable &&
                                          filtered[index].fileUrl != null
                                      ? () =>
                                          _launchDownload(filtered[index].fileUrl!)
                                      : null,
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
    if (filter == 'pending') {
      return documents.where((d) => d.isPending).toList();
    }
    if (filter == 'ready') {
      return documents.where((d) => d.status == 'ready').toList();
    }
    return documents;
  }

  Future<void> _launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceContainerLowest : Colors.transparent,
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

class _DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onDownload;

  const _DocumentCard({
    required this.document,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReady = document.status == 'ready';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Document icon
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
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Title + date
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
                  _formatDate(document.requestedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isReady
                  ? colors.tertiaryContainer.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isReady
                    ? colors.tertiary.withValues(alpha: 0.2)
                    : Colors.amber.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _statusLabel(document.status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isReady ? colors.tertiary : (isDark ? Colors.amber.shade300 : Colors.amber.shade700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Download button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isReady ? colors.primary : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                Icons.download,
                size: 20,
                color: isReady ? colors.onPrimary : colors.outlineVariant,
              ),
              onPressed: onDownload,
              padding: EdgeInsets.zero,
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
