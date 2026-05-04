// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSessionModel _$ChatSessionModelFromJson(Map<String, dynamic> json) =>
    ChatSessionModel(
      id: json['id'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      whatsappPhone: json['whatsapp_phone'] as String?,
      messageCount: (json['message_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChatSessionModelToJson(ChatSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'started_at': instance.startedAt.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'whatsapp_phone': instance.whatsappPhone,
      'message_count': instance.messageCount,
    };
