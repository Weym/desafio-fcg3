import '../../../core/network/dio_client.dart';
import '../../client/models/appointment_model.dart';
import '../models/scheduling_slot_model.dart';

class StaffScheduleService {
  final DioClient _client;

  StaffScheduleService({required DioClient client}) : _client = client;

  /// GET /appointments?status={status}
  Future<List<AppointmentModel>> getAppointments({String? status}) async {
    final queryParams = <String, dynamic>{};
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

  /// GET /scheduling/slots?date_from={from}&date_to={to}
  Future<List<SchedulingSlotModel>> getSlots({
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, dynamic>{};
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    final response = await _client.dio.get(
      '/scheduling/slots',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] as List?) ?? [];
    return list
        .map((e) => SchedulingSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /scheduling/slots — create availability slots
  Future<void> createSlots({
    required String date,
    required String startTime,
    required String endTime,
    required int slotDurationMinutes,
  }) async {
    await _client.dio.post('/scheduling/slots', data: {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_minutes': slotDurationMinutes,
    });
  }

  /// PUT /appointments/{id}/cancel
  Future<void> cancelAppointment(String appointmentId) async {
    await _client.dio.put('/appointments/$appointmentId/cancel');
  }

  /// PUT /appointments/{id}/confirm
  Future<void> confirmAppointment(String appointmentId) async {
    await _client.dio.put('/appointments/$appointmentId/confirm');
  }
}
