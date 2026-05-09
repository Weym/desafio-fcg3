// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      id: json['id'] as String,
      chatSessionId: json['chat_session_id'] as String?,
      role: json['role'] as String,
      content: json['content'] as String,
      mediaType: json['media_type'] as String?,
      whatsappMessageId: json['whatsapp_message_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chat_session_id': instance.chatSessionId,
      'role': instance.role,
      'content': instance.content,
      'media_type': instance.mediaType,
      'whatsapp_message_id': instance.whatsappMessageId,
      'created_at': instance.createdAt.toIso8601String(),
    };
