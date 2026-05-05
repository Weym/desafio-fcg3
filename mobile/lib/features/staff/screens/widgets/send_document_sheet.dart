// TODO: Bulk send (D-18) - add "Enviar para Turma" mode toggle
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/student_summary_model.dart';
import '../../providers/staff_document_provider.dart';

/// Shows the send document bottom sheet. Called from StaffDocumentsScreen FAB.
void showSendDocumentSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _SendDocumentSheet(),
  );
}

class _SendDocumentSheet extends ConsumerStatefulWidget {
  const _SendDocumentSheet();

  @override
  ConsumerState<_SendDocumentSheet> createState() => _SendDocumentSheetState();
}

class _SendDocumentSheetState extends ConsumerState<_SendDocumentSheet> {
  String? _selectedStudentId;
  String? _selectedType;
  String? _pickedFilePath;
  String? _pickedFileName;
  bool _isLoading = false;

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
    // Validate required fields
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um aluno')),
      );
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de documento')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(staffDocumentServiceProvider);
      String? uploadedUrl;

      // Upload file if picked
      if (_pickedFilePath != null) {
        uploadedUrl = await service.uploadFile(
          _pickedFilePath!,
          _pickedFileName!,
        );
      }

      // Create document for the selected student
      await service.createDocument(
        studentId: _selectedStudentId!,
        type: _selectedType!,
        fileUrl: uploadedUrl,
      );

      ref.invalidate(staffDocumentsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento enviado com sucesso!'),
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
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enviar Documento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // Student autocomplete (D-17)
          Autocomplete<StudentSummaryModel>(
            displayStringForOption: (student) => student.name,
            optionsBuilder: (textEditingValue) async {
              if (textEditingValue.text.length < 2) return [];
              final service = ref.read(staffDocumentServiceProvider);
              return service.searchStudents(textEditingValue.text);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Buscar aluno',
                  prefixIcon: Icon(Icons.search),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final student = options.elementAt(index);
                        return ListTile(
                          title: Text(student.name),
                          subtitle: Text(student.email),
                          onTap: () => onSelected(student),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (student) {
              setState(() {
                _selectedStudentId = student.id;
              });
            },
          ),
          const SizedBox(height: 16),
          // Document type dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Tipo de documento',
            ),
            items: const [
              DropdownMenuItem(
                value: 'transcript',
                child: Text('Historico Escolar'),
              ),
              DropdownMenuItem(
                value: 'enrollment_proof',
                child: Text('Comprovante de Matricula'),
              ),
              DropdownMenuItem(
                value: 'declaration',
                child: Text('Declaracao'),
              ),
              DropdownMenuItem(
                value: 'certificate',
                child: Text('Certificado'),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 16),
          // File picker button
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_pickedFileName ?? 'Anexar arquivo (opcional)'),
          ),
          const SizedBox(height: 16),
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
                : const Text('Enviar Documento'),
          ),
        ],
      ),
    );
  }
}
