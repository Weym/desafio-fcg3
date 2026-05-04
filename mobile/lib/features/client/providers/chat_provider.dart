import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';
import '../models/action_log_model.dart';
import '../services/chat_service.dart';

part 'chat_provider.g.dart';

@Riverpod(keepAlive: true)
ChatService chatService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return ChatService(client: client);
}

@riverpod
Future<List<ChatSessionModel>> chatSessions(Ref ref) async {
  final service = ref.watch(chatServiceProvider);
  return service.getSessions();
}

@riverpod
Future<List<ChatMessageModel>> chatMessages(Ref ref, String sessionId) async {
  final service = ref.watch(chatServiceProvider);
  return service.getMessages(sessionId);
}

@riverpod
Future<List<ActionLogModel>> actionLogs(Ref ref, String sessionId) async {
  final service = ref.watch(chatServiceProvider);
  return service.getActionLogs(sessionId);
}
