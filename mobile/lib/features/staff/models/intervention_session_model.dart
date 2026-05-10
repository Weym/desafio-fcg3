import 'package:json_annotation/json_annotation.dart';

part 'intervention_session_model.g.dart';

@JsonSerializable()
class InterventionSessionModel {
  final String id;
  @JsonKey(name: 'student_id')
  final String? studentId;
  @JsonKey(name: 'whatsapp_phone')
  final String? whatsappPhone;
  final String status; // 'human_needed', 'human_active', 'closed'
  @JsonKey(name: 'assigned_staff_id')
  final String? assignedStaffId;
  @JsonKey(name: 'escalation_reason')
  final String? escalationReason;
  @JsonKey(name: 'student_name')
  final String? studentName;
  @JsonKey(name: 'student_email')
  final String? studentEmail;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'message_count')
  final int? messageCount;

  const InterventionSessionModel({
    required this.id,
    this.studentId,
    this.whatsappPhone,
    required this.status,
    this.assignedStaffId,
    this.escalationReason,
    this.studentName,
    this.studentEmail,
    required this.startedAt,
    this.updatedAt,
    this.messageCount,
  });

  factory InterventionSessionModel.fromJson(Map<String, dynamic> json) =>
      _$InterventionSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$InterventionSessionModelToJson(this);

  bool get isPending => status == 'human_needed';
  bool get isActive => status == 'human_active';
  bool get isResolved => status == 'closed';

  /// Display name: student name or phone or truncated ID
  String get displayName =>
      studentName ?? whatsappPhone ?? 'Aluno #${id.substring(0, 8)}';

  /// Display identifier: email or phone
  String get displayIdentifier => studentEmail ?? whatsappPhone ?? '';
}
