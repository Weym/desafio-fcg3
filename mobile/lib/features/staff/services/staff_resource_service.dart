import '../../../core/network/dio_client.dart';
import '../models/resource_model.dart';

class StaffResourceService {
  final DioClient _client;

  StaffResourceService({required DioClient client}) : _client = client;

  /// GET /resources?resource_type={type}
  Future<List<ResourceModel>> getResources({String? resourceType}) async {
    final queryParams = <String, dynamic>{};
    if (resourceType != null) queryParams['resource_type'] = resourceType;
    final response = await _client.dio.get(
      '/resources',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => ResourceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /resources
  Future<ResourceModel> createResource({
    required String name,
    required String resourceType,
    int? capacity,
    String? location,
    String? description,
    bool requiresAuthorization = false,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'resource_type': resourceType,
      'requires_authorization': requiresAuthorization,
    };
    if (capacity != null) body['capacity'] = capacity;
    if (location != null) body['location'] = location;
    if (description != null) body['description'] = description;

    final response = await _client.dio.post('/resources', data: body);
    return ResourceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /resources/{id}
  Future<ResourceModel> updateResource(
    String id, {
    String? name,
    String? resourceType,
    int? capacity,
    String? location,
    String? description,
    bool? requiresAuthorization,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (resourceType != null) body['resource_type'] = resourceType;
    if (capacity != null) body['capacity'] = capacity;
    if (location != null) body['location'] = location;
    if (description != null) body['description'] = description;
    if (requiresAuthorization != null) {
      body['requires_authorization'] = requiresAuthorization;
    }

    final response = await _client.dio.put('/resources/$id', data: body);
    return ResourceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /resources/{id} — soft-delete (sets is_available=false)
  Future<void> deleteResource(String id) async {
    await _client.dio.delete('/resources/$id');
  }
}
