import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../client/models/document_model.dart';
import '../models/student_summary_model.dart';

class StaffDocumentService {
  final DioClient _client;

  StaffDocumentService({required DioClient client}) : _client = client;

  /// GET /documents?status={status}
  Future<List<DocumentModel>> getDocuments({String? status}) async {
    final queryParams = <String, dynamic>{};
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

  /// PUT /documents/{id}/status — update document status
  Future<void> updateDocumentStatus(
    String documentId, {
    required String status,
    String? fileUrl,
  }) async {
    await _client.dio.put('/documents/$documentId/status', data: {
      'status': status,
      // ignore: use_null_aware_elements
      if (fileUrl != null) 'file_url': fileUrl,
    });
  }

  /// POST /documents/upload — upload file and return URL
  Future<String> uploadFile(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _client.dio.post(
      '/documents/upload',
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  /// POST /documents — create document proactively (staff sends to student)
  Future<DocumentModel> createDocument({
    required String studentId,
    required String type,
    String? fileUrl,
    String? notes,
  }) async {
    final response = await _client.dio.post('/documents', data: {
      'student_id': studentId,
      'type': type,
      'status': fileUrl != null ? 'ready' : 'processing',
      // ignore: use_null_aware_elements
      if (fileUrl != null) 'file_url': fileUrl,
      // ignore: use_null_aware_elements
      if (notes != null) 'notes': notes,
    });
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /students?search={query} — for autocomplete
  Future<List<StudentSummaryModel>> searchStudents(String query) async {
    final response = await _client.dio.get('/students', queryParameters: {
      'search': query,
      'per_page': 10,
    });
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => StudentSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
