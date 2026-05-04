// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      mediaType: json['media_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'media_type': instance.mediaType,
      'created_at': instance.createdAt.toIso8601String(),
    };
