import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/document_provider.dart';

/// Shows the document request bottom sheet. Called from DocumentsScreen FAB.
void showDocumentRequestSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _DocumentRequestSheet(),
  );
}

class _DocumentRequestSheet extends ConsumerStatefulWidget {
  const _DocumentRequestSheet();

  @override
  ConsumerState<_DocumentRequestSheet> createState() =>
      _DocumentRequestSheetState();
}

class _DocumentRequestSheetState extends ConsumerState<_DocumentRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _notes;
  bool _isLoading = false;

  static const _documentTypes = <String, String>{
    'transcript': 'Historico Escolar',
    'enrollment_proof': 'Comprovante de Matricula',
    'declaration': 'Declaracao',
    'certificate': 'Certificado',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final service = ref.read(documentServiceProvider);
      await service.requestDocument(
        type: _selectedType!,
        notes: _notes?.isNotEmpty == true ? _notes : null,
      );
      ref.invalidate(documentsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento solicitado com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao solicitar documento. Tente novamente.'),
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
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Solicitar Documento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Document type dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de documento',
              ),
              initialValue: _selectedType,
              items: _documentTypes.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) =>
                  value == null ? 'Selecione o tipo de documento' : null,
            ),
            const SizedBox(height: 16),
            // Notes text field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observacao (opcional)',
                hintText: 'Ex: Preciso para estagio',
              ),
              maxLines: 3,
              onSaved: (value) => _notes = value,
            ),
            const SizedBox(height: 24),
            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Solicitar'),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
