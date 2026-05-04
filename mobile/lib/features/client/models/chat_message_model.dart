import 'package:json_annotation/json_annotation.dart';

part 'chat_message_model.g.dart';

@JsonSerializable()
class ChatMessageModel {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  @JsonKey(name: 'media_type')
  final String? mediaType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.mediaType,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
