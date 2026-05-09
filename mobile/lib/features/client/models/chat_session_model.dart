import 'package:json_annotation/json_annotation.dart';

part 'chat_session_model.g.dart';

@JsonSerializable()
class ChatSessionModel {
  final String id;
  @JsonKey(name: 'student_id')
  final String? studentId;
  @JsonKey(name: 'whatsapp_phone')
  final String? whatsappPhone;
  final String status; // 'active' or 'closed'
  @JsonKey(name: 'verification_state')
  final String? verificationState;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'message_count')
  final int? messageCount;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'student_name')
  final String? studentName;
  @JsonKey(name: 'student_ra')
  final String? studentRa;

  const ChatSessionModel({
    required this.id,
    this.studentId,
    this.whatsappPhone,
    required this.status,
    this.verificationState,
    required this.startedAt,
    this.endedAt,
    this.updatedAt,
    this.messageCount,
    this.name,
    this.studentName,
    this.studentRa,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionModelToJson(this);

  bool get isActive => status == 'active';
}
