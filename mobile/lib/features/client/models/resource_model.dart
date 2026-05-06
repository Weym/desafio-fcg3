import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'resource_model.g.dart';

@JsonSerializable()
class ClientResourceModel {
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

  const ClientResourceModel({
    required this.id,
    required this.name,
    required this.resourceType,
    this.capacity,
    this.location,
    this.description,
    required this.requiresAuthorization,
    required this.isAvailable,
  });

  factory ClientResourceModel.fromJson(Map<String, dynamic> json) =>
      _$ClientResourceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClientResourceModelToJson(this);

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

  /// Icon representing the resource type.
  IconData get typeIcon => switch (resourceType) {
        'room' => Icons.meeting_room,
        'lab' => Icons.science,
        'equipment' => Icons.devices,
        'auditorium' => Icons.theater_comedy,
        'study_room' => Icons.auto_stories,
        'sports_court' => Icons.sports_tennis,
        _ => Icons.category,
      };
}
