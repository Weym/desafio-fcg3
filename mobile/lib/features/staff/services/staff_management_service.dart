import '../../../core/network/dio_client.dart';
import '../models/staff_member_model.dart';

class StaffManagementService {
  final DioClient _client;

  StaffManagementService({required DioClient client}) : _client = client;

  /// GET /staff/members?page=1&per_page=20&search=&status=
  Future<({List<StaffMemberModel> items, int total})> listStaff({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status;
    final response = await _client.dio.get(
      '/staff/members',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    final total = response.data['pagination']['total'] as int;
    return (
      items: data
          .map((e) => StaffMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
    );
  }

  /// GET /staff/members/{id}
  Future<StaffMemberModel> getStaffMember(String id) async {
    final response = await _client.dio.get('/staff/members/$id');
    return StaffMemberModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /staff/members
  Future<StaffMemberModel> createStaff(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/staff/members', data: data);
    return StaffMemberModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /staff/members/{id}
  Future<StaffMemberModel> updateStaff(
      String id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/staff/members/$id', data: data);
    return StaffMemberModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /staff/members/{id} — soft deactivation
  Future<void> deleteStaff(String id) async {
    await _client.dio.delete('/staff/members/$id');
  }
}
