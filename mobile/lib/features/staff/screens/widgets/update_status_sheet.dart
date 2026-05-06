import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../client/models/document_model.dart';
import '../../providers/staff_document_provider.dart';

/// Shows the update status bottom sheet for a document.
void showUpdateStatusSheet(
    BuildContext context, WidgetRef ref, DocumentModel document) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _UpdateStatusSheet(document: document),
  );
}

class _UpdateStatusSheet extends ConsumerStatefulWidget {
  final DocumentModel document;

  const _UpdateStatusSheet({required this.document});

  @override
  ConsumerState<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<_UpdateStatusSheet> {
  late String _selectedStatus;
  String? _pickedFilePath;
  String? _pickedFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.document.status;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      // Validate max 10MB
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo excede o tamanho maximo de 10MB'),
            ),
          );
        }
        return;
      }
      setState(() {
        _pickedFilePath = file.path;
        _pickedFileName = file.name;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(staffDocumentServiceProvider);
      String? uploadedUrl;

      // If status is 'ready' and file is picked, upload first
      if (_selectedStatus == 'ready' && _pickedFilePath != null) {
        uploadedUrl = await service.uploadFile(
          _pickedFilePath!,
          _pickedFileName!,
        );
      }

      // Update document status
      await service.updateDocumentStatus(
        widget.document.id,
        status: _selectedStatus,
        fileUrl: uploadedUrl,
      );

      ref.invalidate(staffDocumentsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status atualizado com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao executar acao. Tente novamente.'),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Atualizar Status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // Status dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Novo status',
            ),
            initialValue: _selectedStatus,
            items: const [
              DropdownMenuItem(
                  value: 'requested', child: Text('Solicitado')),
              DropdownMenuItem(
                  value: 'processing', child: Text('Processando')),
              DropdownMenuItem(value: 'ready', child: Text('Pronto')),
              DropdownMenuItem(value: 'delivered', child: Text('Entregue')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
          ),
          const SizedBox(height: 16),
          // Conditional file picker (D-15): only when status == 'ready'
          Visibility(
            visible: _selectedStatus == 'ready',
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_pickedFileName ?? 'Selecionar arquivo'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
                : const Text('Atualizar Status'),
          ),
        ],
      ),
    );
  }
}
