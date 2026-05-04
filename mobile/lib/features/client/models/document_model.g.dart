// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentModel _$DocumentModelFromJson(Map<String, dynamic> json) =>
    DocumentModel(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      fileUrl: json['file_url'] as String?,
      notes: json['notes'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$DocumentModelToJson(DocumentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'status': instance.status,
      'file_url': instance.fileUrl,
      'notes': instance.notes,
      'requested_at': instance.requestedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
    };
