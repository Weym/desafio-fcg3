// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionLogModel _$ActionLogModelFromJson(Map<String, dynamic> json) =>
    ActionLogModel(
      id: json['id'] as String,
      toolName: json['tool_name'] as String,
      inputParams: json['input_params'] as Map<String, dynamic>,
      outputResult: json['output_result'] as Map<String, dynamic>?,
      reasoning: json['reasoning'] as String?,
      latencyMs: (json['latency_ms'] as num?)?.toInt(),
      retry: json['retry'] as bool? ?? false,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActionLogModelToJson(ActionLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tool_name': instance.toolName,
      'input_params': instance.inputParams,
      'output_result': instance.outputResult,
      'reasoning': instance.reasoning,
      'latency_ms': instance.latencyMs,
      'retry': instance.retry,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };
