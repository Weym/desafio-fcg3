import '../../../core/network/dio_client.dart';
import '../../client/models/chat_session_model.dart';
import '../../client/models/chat_message_model.dart';
import '../../client/models/action_log_model.dart';

class StaffChatService {
  final DioClient _client;

  StaffChatService({required DioClient client}) : _client = client;

  /// GET /chat-sessions?status={status}
  Future<List<ChatSessionModel>> getSessions({String? status}) async {
    final queryParams = <String, dynamic>{};
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

  /// Aggregated statistics (computed from all sessions)
  /// Returns total sessions, active count, and closed count
  Future<Map<String, dynamic>> getStatistics() async {
    final sessions = await getSessions();
    final totalSessions = sessions.length;
    final activeSessions = sessions.where((s) => s.isActive).length;

    return {
      'total_sessions': totalSessions,
      'active_sessions': activeSessions,
      'closed_sessions': totalSessions - activeSessions,
    };
  }
}
