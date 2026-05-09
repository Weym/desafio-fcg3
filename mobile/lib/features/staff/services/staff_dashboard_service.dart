import '../../../core/network/dio_client.dart';
import '../models/staff_dashboard_model.dart';

class StaffDashboardService {
  final DioClient _client;

  StaffDashboardService({required DioClient client}) : _client = client;

  /// GET /staff/dashboard
  Future<StaffDashboardModel> getDashboard() async {
    final response = await _client.dio.get('/staff/dashboard');
    return StaffDashboardModel.fromJson(response.data as Map<String, dynamic>);
  }
}
