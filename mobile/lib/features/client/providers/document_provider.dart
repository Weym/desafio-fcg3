import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

part 'document_provider.g.dart';

@Riverpod(keepAlive: true)
DocumentService documentService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return DocumentService(client: client);
}

@riverpod
Future<List<DocumentModel>> documents(Ref ref) async {
  final service = ref.watch(documentServiceProvider);
  final docs = await service.getDocuments();
  CacheTTL.schedule(ref, 'documents');
  return docs;
}

@riverpod
class DocumentFilter extends _$DocumentFilter {
  @override
  String? build() => null; // null = "Todos"

  void setFilter(String? status) => state = status;
}
