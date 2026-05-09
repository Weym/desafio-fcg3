import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../../client/models/document_model.dart';
import '../models/student_summary_model.dart';
import '../services/staff_document_service.dart';

part 'staff_document_provider.g.dart';

@Riverpod(keepAlive: true)
StaffDocumentService staffDocumentService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffDocumentService(client: client);
}

@riverpod
Future<List<DocumentModel>> staffDocuments(Ref ref) async {
  final service = ref.watch(staffDocumentServiceProvider);
  final docs = await service.getDocuments();
  CacheTTL.schedule(ref, 'staffDocuments');
  return docs;
}

@riverpod
class StaffDocumentFilter extends _$StaffDocumentFilter {
  @override
  String? build() => null; // null = "Todos"

  void setFilter(String? status) => state = status;
}

@riverpod
class StaffDocumentTypeFilter extends _$StaffDocumentTypeFilter {
  @override
  String? build() => null; // null = "Todos"

  void setFilter(String? type) => state = type;
}

@riverpod
Future<List<StudentSummaryModel>> studentSearch(Ref ref, String query) async {
  if (query.length < 2) return [];
  final service = ref.watch(staffDocumentServiceProvider);
  return service.searchStudents(query);
}
