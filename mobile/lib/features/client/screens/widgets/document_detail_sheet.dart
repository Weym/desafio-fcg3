import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/document_model.dart';

/// Shows the document detail bottom sheet with full info.
void showDocumentDetailSheet(BuildContext context, DocumentModel document) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _DocumentDetailSheet(document: document),
  );
}

class _DocumentDetailSheet extends StatelessWidget {
  final DocumentModel document;
  const _DocumentDetailSheet({required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          // Header with icon
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
          _DetailRow(label: 'Status', value: _statusLabel(document.status)),
          _DetailRow(label: 'Tipo', value: _typeLabel(document.type)),
          _DetailRow(
            label: 'Solicitado em',
            value: _formatDateTime(document.requestedAt),
          ),
          if (document.completedAt != null)
            _DetailRow(
              label: 'Concluido em',
              value: _formatDateTime(document.completedAt!),
            ),
          if (document.notes != null && document.notes!.isNotEmpty)
            _DetailRow(label: 'Observacoes', value: document.notes!),

          const SizedBox(height: 24),

          // Download button (if ready)
          if (document.isDownloadable && document.fileUrl != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Baixar documento'),
                onPressed: () => launchUrl(
                  Uri.parse(document.fileUrl!),
                  mode: LaunchMode.externalApplication,
                ),
              ),
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
            width: 120,
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
      'ready' => 'Pronto para download',
      'delivered' => 'Entregue',
      _ => status,
    };
