import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';
import '../models/action_log_model.dart';
import '../services/chat_service.dart';

part 'chat_provider.g.dart';

enum ChatStatusFilter { all, active, inactive }

@Riverpod(keepAlive: true)
ChatService chatService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return ChatService(client: client);
}

@riverpod
Future<List<ChatSessionModel>> chatSessions(Ref ref) async {
  final service = ref.watch(chatServiceProvider);
  final sessions = await service.getSessions();
  CacheTTL.schedule(ref, 'chatSessions');
  return sessions;
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

@riverpod
Future<void> renameChatSession(Ref ref, String sessionId, String newName) async {
  final service = ref.watch(chatServiceProvider);
  await service.renameSession(sessionId, newName);
  ref.invalidate(chatSessionsProvider);
}

@riverpod
class ChatFilterNotifier extends _$ChatFilterNotifier {
  @override
  ChatStatusFilter build() => ChatStatusFilter.all;

  void setFilter(ChatStatusFilter filter) => state = filter;
}
