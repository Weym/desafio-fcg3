import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../auth/providers/auth_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSendDocumentSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Enviar'),
      ),
      body: Column(
        children: [
          // Filter chips row (D-14)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: filter == null,
                  onSelected: (_) => ref
                      .read(staffDocumentFilterProvider.notifier)
                      .setFilter(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pendentes'),
                  selected: filter == 'requested',
                  onSelected: (_) => ref
                      .read(staffDocumentFilterProvider.notifier)
                      .setFilter(
                          filter == 'requested' ? null : 'requested'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Processando'),
                  selected: filter == 'processing',
                  onSelected: (_) => ref
                      .read(staffDocumentFilterProvider.notifier)
                      .setFilter(
                          filter == 'processing' ? null : 'processing'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Prontos'),
                  selected: filter == 'ready',
                  onSelected: (_) => ref
                      .read(staffDocumentFilterProvider.notifier)
                      .setFilter(filter == 'ready' ? null : 'ready'),
                ),
              ],
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
                  onRetry: () => ref.invalidate(staffDocumentsProvider),
                ),
              ),
              data: (documents) {
                final filtered = _applyFilter(documents, filter);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.folder_open,
                    message: 'Nenhum documento disponivel',
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _StaffDocumentCard(
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

// --- Helper functions ---

String _typeLabel(String type) => switch (type) {
      'transcript' => 'Historico Escolar',
      'enrollment_proof' => 'Comprovante de Matricula',
      'declaration' => 'Declaracao',
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

Color _statusBackgroundColor(String status) => switch (status) {
      'requested' || 'processing' => Colors.amber.shade100,
      'ready' => Colors.green.shade100,
      'delivered' => Colors.grey.shade200,
      _ => Colors.grey.shade200,
    };

Color _statusTextColor(String status) => switch (status) {
      'requested' || 'processing' => Colors.amber.shade800,
      'ready' => Colors.green.shade800,
      'delivered' => Colors.grey.shade700,
      _ => Colors.grey.shade700,
    };

Color _iconColor(String status) => switch (status) {
      'requested' || 'processing' => Colors.amber.shade700,
      'ready' => Colors.green.shade700,
      'delivered' => Colors.grey.shade600,
      _ => Colors.grey.shade600,
    };

// --- Document card widget ---

class _StaffDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const _StaffDocumentCard({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColor(document.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description,
                  color: _iconColor(document.status),
                ),
              ),
              const SizedBox(width: 12),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(document.type),
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solicitado em ${_formatDate(document.requestedAt)}',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor(document.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(document.status),
                  style: TextStyle(
                    color: _statusTextColor(document.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
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
