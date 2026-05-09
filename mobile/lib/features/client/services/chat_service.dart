import '../../../core/network/dio_client.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';
import '../models/action_log_model.dart';

class ChatService {
  final DioClient _client;

  ChatService({required DioClient client}) : _client = client;

  /// GET /chat-sessions?student_id={studentId}&status={status}
  Future<List<ChatSessionModel>> getSessions({
    String? studentId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (studentId != null) queryParams['student_id'] = studentId;
    if (status != null) queryParams['status'] = status;
    final response = await _client.dio.get(
      '/chat-sessions',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /chat-sessions/{id}/messages
  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final response = await _client.dio.get(
      '/chat-sessions/$sessionId/messages',
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PUT /chat-sessions/{id}
  Future<void> renameSession(String sessionId, String newName) async {
    await _client.dio.put(
      '/chat-sessions/$sessionId',
      data: {'name': newName},
    );
  }

  /// GET /chat-sessions/{id}/action-logs
  Future<List<ActionLogModel>> getActionLogs(String sessionId) async {
    final response = await _client.dio.get(
      '/chat-sessions/$sessionId/action-logs',
    );
    final data = response.data;
    final list = data is Map ? (data['data'] as List?) ?? [] : data as List;
    return list
        .map((e) => ActionLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
