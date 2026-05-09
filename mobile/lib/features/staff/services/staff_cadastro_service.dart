import '../../../core/network/dio_client.dart';
import '../models/staff_student_model.dart';

class StaffCadastroService {
  final DioClient _client;

  StaffCadastroService({required DioClient client}) : _client = client;

  /// GET /students
  Future<List<StaffStudentModel>> getStudents() async {
    final response = await _client.dio.get('/students');
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => StaffStudentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /students
  Future<StaffStudentModel> createStudent(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/students', data: data);
    return StaffStudentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /students/{id}
  Future<StaffStudentModel> updateStudent(
      String id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/students/$id', data: data);
    return StaffStudentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /students/{id}
  Future<void> deleteStudent(String id) async {
    await _client.dio.delete('/students/$id');
  }

  /// PUT /students/{id} — toggle status
  Future<void> toggleStatus(String id, bool activate) async {
    await _client.dio
        .put('/students/$id', data: {'status': activate ? 'active' : 'inactive'});
  }
}
