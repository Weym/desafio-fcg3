// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourceModel _$ResourceModelFromJson(Map<String, dynamic> json) =>
    ResourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      resourceType: json['resource_type'] as String,
      capacity: (json['capacity'] as num?)?.toInt(),
      location: json['location'] as String?,
      description: json['description'] as String?,
      requiresAuthorization: json['requires_authorization'] as bool,
      isAvailable: json['is_available'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ResourceModelToJson(ResourceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'resource_type': instance.resourceType,
      'capacity': instance.capacity,
      'location': instance.location,
      'description': instance.description,
      'requires_authorization': instance.requiresAuthorization,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt.toIso8601String(),
    };
