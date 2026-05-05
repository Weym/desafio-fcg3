import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../client/models/chat_session_model.dart';
import '../../client/models/chat_message_model.dart';
import '../../client/models/action_log_model.dart';
import '../services/staff_chat_service.dart';

part 'staff_chat_provider.g.dart';

@Riverpod(keepAlive: true)
StaffChatService staffChatService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffChatService(client: client);
}

@riverpod
Future<List<ChatSessionModel>> staffChatSessions(Ref ref) async {
  final service = ref.watch(staffChatServiceProvider);
  return service.getSessions();
}

@riverpod
Future<List<ChatMessageModel>> staffChatMessages(Ref ref, String sessionId) async {
  final service = ref.watch(staffChatServiceProvider);
  return service.getMessages(sessionId);
}

@riverpod
Future<List<ActionLogModel>> staffActionLogs(Ref ref, String sessionId) async {
  final service = ref.watch(staffChatServiceProvider);
  return service.getActionLogs(sessionId);
}

@riverpod
Future<Map<String, dynamic>> staffChatStatistics(Ref ref) async {
  final service = ref.watch(staffChatServiceProvider);
  return service.getStatistics();
}
