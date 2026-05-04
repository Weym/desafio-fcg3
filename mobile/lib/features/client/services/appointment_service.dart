import '../../../core/network/dio_client.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final DioClient _client;

  AppointmentService({required DioClient client}) : _client = client;

  /// GET /appointments?student_id={studentId}&status={status}
  Future<List<AppointmentModel>> getAppointments({
    String? studentId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (studentId != null) queryParams['student_id'] = studentId;
    if (status != null) queryParams['status'] = status;
    final response = await _client.dio.get(
      '/appointments',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
