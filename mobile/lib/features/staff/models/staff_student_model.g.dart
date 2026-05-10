// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_student_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffStudentModel _$StaffStudentModelFromJson(Map<String, dynamic> json) =>
    StaffStudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      ra: json['registration_number'] as String?,
      semester: (json['semester'] as num?)?.toInt(),
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$StaffStudentModelToJson(StaffStudentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'registration_number': instance.ra,
      'semester': instance.semester,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };
