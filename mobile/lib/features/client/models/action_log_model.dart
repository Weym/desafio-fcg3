import 'package:json_annotation/json_annotation.dart';

part 'action_log_model.g.dart';

@JsonSerializable()
class ActionLogModel {
  final String id;
  @JsonKey(name: 'chat_session_id')
  final String? chatSessionId;
  @JsonKey(name: 'tool_name')
  final String toolName;
  @JsonKey(name: 'input_params')
  final Map<String, dynamic> inputParams;
  @JsonKey(name: 'output_result')
  final Map<String, dynamic>? outputResult;
  final String? reasoning;
  @JsonKey(name: 'latency_ms')
  final int? latencyMs;
  final bool retry;
  final String status; // 'success', 'error', 'retry_success'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ActionLogModel({
    required this.id,
    this.chatSessionId,
    required this.toolName,
    required this.inputParams,
    this.outputResult,
    this.reasoning,
    this.latencyMs,
    this.retry = false,
    required this.status,
    required this.createdAt,
  });

  factory ActionLogModel.fromJson(Map<String, dynamic> json) =>
      _$ActionLogModelFromJson(json);
  Map<String, dynamic> toJson() => _$ActionLogModelToJson(this);

  bool get isError => status == 'error';
}
