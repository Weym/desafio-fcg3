import 'package:json_annotation/json_annotation.dart';

part 'chat_session_model.g.dart';

@JsonSerializable()
class ChatSessionModel {
  final String id;
  final String status; // 'active' or 'closed'
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  @JsonKey(name: 'whatsapp_phone')
  final String? whatsappPhone;
  @JsonKey(name: 'message_count')
  final int? messageCount;

  const ChatSessionModel({
    required this.id,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.whatsappPhone,
    this.messageCount,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionModelToJson(this);

  bool get isActive => status == 'active';
}
