import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../../client/models/chat_message_model.dart';
import '../models/intervention_session_model.dart';
import '../services/staff_intervention_service.dart';

part 'staff_intervention_provider.g.dart';

@Riverpod(keepAlive: true)
StaffInterventionService staffInterventionService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffInterventionService(client: client);
}

@riverpod
Future<List<InterventionSessionModel>> interventionSessions(Ref ref) async {
  final service = ref.watch(staffInterventionServiceProvider);
  final sessions = await service.getInterventionSessions();
  CacheTTL.schedule(ref, 'interventionSessions');
  return sessions;
}

@riverpod
Future<List<ChatMessageModel>> interventionMessages(
    Ref ref, String sessionId) async {
  final service = ref.watch(staffInterventionServiceProvider);
  return service.getSessionMessages(sessionId);
}
