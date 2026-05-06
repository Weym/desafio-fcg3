import '../../../core/network/dio_client.dart';
import '../../client/models/chat_message_model.dart';
import '../models/intervention_session_model.dart';

class StaffInterventionService {
  final DioClient _client;

  StaffInterventionService({required DioClient client}) : _client = client;

  /// GET /chat-sessions/interventions
  Future<List<InterventionSessionModel>> getInterventionSessions() async {
    final response = await _client.dio.get('/chat-sessions/interventions');
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) =>
            InterventionSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /chat-sessions/{id}/assign
  Future<InterventionSessionModel> assignSession(String sessionId) async {
    final response = await _client.dio.post(
      '/chat-sessions/$sessionId/assign',
    );
    return InterventionSessionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// POST /chat-sessions/{id}/reply
  Future<ChatMessageModel> replyToSession(
      String sessionId, String content) async {
    final response = await _client.dio.post(
      '/chat-sessions/$sessionId/reply',
      data: {'content': content},
    );
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /chat-sessions/{id}/resolve
  Future<void> resolveSession(String sessionId) async {
    await _client.dio.put('/chat-sessions/$sessionId/resolve');
  }

  /// GET /chat-sessions/{id}/messages (reuses existing endpoint)
  Future<List<ChatMessageModel>> getSessionMessages(String sessionId) async {
    final response = await _client.dio.get(
      '/chat-sessions/$sessionId/messages',
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
