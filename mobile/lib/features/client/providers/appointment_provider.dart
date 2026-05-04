import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

part 'appointment_provider.g.dart';

@Riverpod(keepAlive: true)
AppointmentService appointmentService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return AppointmentService(client: client);
}

@riverpod
Future<List<AppointmentModel>> appointments(Ref ref) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointments();
}
