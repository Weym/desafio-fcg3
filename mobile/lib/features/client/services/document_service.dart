import '../../../core/network/dio_client.dart';
import '../models/document_model.dart';

class DocumentService {
  final DioClient _client;

  DocumentService({required DioClient client}) : _client = client;

  /// GET /documents?student_id={studentId}&status={status}
  Future<List<DocumentModel>> getDocuments({
    String? studentId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (studentId != null) queryParams['student_id'] = studentId;
    if (status != null) queryParams['status'] = status;
    final response = await _client.dio.get(
      '/documents',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /documents/{id}
  Future<DocumentModel> getDocument(String documentId) async {
    final response = await _client.dio.get('/documents/$documentId');
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /documents — request new document
  Future<DocumentModel> requestDocument({
    required String type,
    String? notes,
  }) async {
    final response = await _client.dio.post(
      '/documents',
      data: {
        'type': type,
        // ignore: use_null_aware_elements
        if (notes != null) 'notes': notes,
      },
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
