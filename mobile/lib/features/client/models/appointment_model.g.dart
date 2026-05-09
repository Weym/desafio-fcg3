// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentModel _$AppointmentModelFromJson(Map<String, dynamic> json) =>
    AppointmentModel(
      id: json['id'] as String,
      slotId: json['slot_id'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      slotDate: json['slot_date'] as String?,
      slotStartTime: json['slot_start_time'] as String?,
      endTime: json['end_time'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AppointmentModelToJson(AppointmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slot_id': instance.slotId,
      'reason': instance.reason,
      'status': instance.status,
      'slot_date': instance.slotDate,
      'slot_start_time': instance.slotStartTime,
      'end_time': instance.endTime,
      'created_at': instance.createdAt.toIso8601String(),
    };
