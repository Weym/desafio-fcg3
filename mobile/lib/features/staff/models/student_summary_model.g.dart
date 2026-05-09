// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentSummaryModel _$StudentSummaryModelFromJson(Map<String, dynamic> json) =>
    StudentSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      registrationNumber: json['registration_number'] as String?,
      semester: (json['semester'] as num?)?.toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$StudentSummaryModelToJson(
  StudentSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'registration_number': instance.registrationNumber,
  'semester': instance.semester,
  'status': instance.status,
};
