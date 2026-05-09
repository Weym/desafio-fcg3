import 'package:json_annotation/json_annotation.dart';

part 'resource_model.g.dart';

@JsonSerializable()
class ResourceModel {
  final String id;
  final String name;
  @JsonKey(name: 'resource_type')
  final String resourceType;
  final int? capacity;
  final String? location;
  final String? description;
  @JsonKey(name: 'requires_authorization')
  final bool requiresAuthorization;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.resourceType,
    this.capacity,
    this.location,
    this.description,
    required this.requiresAuthorization,
    required this.isAvailable,
    required this.createdAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) =>
      _$ResourceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceModelToJson(this);

  /// Portuguese label for the resource type.
  String get typeLabel => switch (resourceType) {
        'room' => 'Sala',
        'lab' => 'Laboratório',
        'equipment' => 'Equipamento',
        'auditorium' => 'Auditório',
        'study_room' => 'Sala de Estudos',
        'sports_court' => 'Quadra Esportiva',
        _ => resourceType,
      };
}
