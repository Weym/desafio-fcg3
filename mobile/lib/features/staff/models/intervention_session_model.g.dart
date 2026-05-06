// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterventionSessionModel _$InterventionSessionModelFromJson(
  Map<String, dynamic> json,
) => InterventionSessionModel(
  id: json['id'] as String,
  studentId: json['student_id'] as String?,
  whatsappPhone: json['whatsapp_phone'] as String?,
  status: json['status'] as String,
  assignedStaffId: json['assigned_staff_id'] as String?,
  escalationReason: json['escalation_reason'] as String?,
  studentName: json['student_name'] as String?,
  studentEmail: json['student_email'] as String?,
  startedAt: DateTime.parse(json['started_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  messageCount: (json['message_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$InterventionSessionModelToJson(
  InterventionSessionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'whatsapp_phone': instance.whatsappPhone,
  'status': instance.status,
  'assigned_staff_id': instance.assignedStaffId,
  'escalation_reason': instance.escalationReason,
  'student_name': instance.studentName,
  'student_email': instance.studentEmail,
  'started_at': instance.startedAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'message_count': instance.messageCount,
};
