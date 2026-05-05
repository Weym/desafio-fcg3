import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/staff_dashboard_model.dart';
import '../services/staff_dashboard_service.dart';

part 'staff_dashboard_provider.g.dart';

@Riverpod(keepAlive: true)
StaffDashboardService staffDashboardService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffDashboardService(client: client);
}

@riverpod
Future<StaffDashboardModel> staffDashboard(Ref ref) async {
  final service = ref.watch(staffDashboardServiceProvider);
  final dashboard = await service.getDashboard();
  CacheTTL.schedule(ref, 'staffDashboard');
  return dashboard;
}
