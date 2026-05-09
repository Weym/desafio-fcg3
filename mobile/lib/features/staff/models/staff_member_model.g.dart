// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffMemberModel _$StaffMemberModelFromJson(Map<String, dynamic> json) =>
    StaffMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      position: json['position'] as String?,
      workSchedule: json['work_schedule'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$StaffMemberModelToJson(StaffMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'status': instance.status,
      'position': instance.position,
      'work_schedule': instance.workSchedule,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
