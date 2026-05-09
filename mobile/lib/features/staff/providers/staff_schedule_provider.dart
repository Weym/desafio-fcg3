import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../../client/models/appointment_model.dart';
import '../models/scheduling_slot_model.dart';
import '../services/staff_schedule_service.dart';

part 'staff_schedule_provider.g.dart';

@Riverpod(keepAlive: true)
StaffScheduleService staffScheduleService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffScheduleService(client: client);
}

@riverpod
Future<List<AppointmentModel>> staffAppointments(Ref ref) async {
  final service = ref.watch(staffScheduleServiceProvider);
  final appointments = await service.getAppointments();
  CacheTTL.schedule(ref, 'staffAppointments');
  return appointments;
}

@riverpod
Future<List<SchedulingSlotModel>> staffSlots(Ref ref) async {
  final service = ref.watch(staffScheduleServiceProvider);
  return service.getSlots();
}

@riverpod
class StaffScheduleFilter extends _$StaffScheduleFilter {
  @override
  String? build() => null; // null = "Todos"

  void setFilter(String? status) => state = status;
}
