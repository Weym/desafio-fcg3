// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSessionModel _$ChatSessionModelFromJson(Map<String, dynamic> json) =>
    ChatSessionModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String?,
      whatsappPhone: json['whatsapp_phone'] as String?,
      status: json['status'] as String,
      verificationState: json['verification_state'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      messageCount: (json['message_count'] as num?)?.toInt(),
      name: json['name'] as String?,
      studentName: json['student_name'] as String?,
      studentRa: json['student_ra'] as String?,
    );

Map<String, dynamic> _$ChatSessionModelToJson(ChatSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'whatsapp_phone': instance.whatsappPhone,
      'status': instance.status,
      'verification_state': instance.verificationState,
      'started_at': instance.startedAt.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'message_count': instance.messageCount,
      'name': instance.name,
      'student_name': instance.studentName,
      'student_ra': instance.studentRa,
    };
