// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduling_slot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotStaffInfo _$SlotStaffInfoFromJson(Map<String, dynamic> json) =>
    SlotStaffInfo(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$SlotStaffInfoToJson(SlotStaffInfo instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

SchedulingSlotModel _$SchedulingSlotModelFromJson(Map<String, dynamic> json) =>
    SchedulingSlotModel(
      id: json['id'] as String,
      staff: json['staff'] == null
          ? null
          : SlotStaffInfo.fromJson(json['staff'] as Map<String, dynamic>),
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool,
    );

Map<String, dynamic> _$SchedulingSlotModelToJson(
  SchedulingSlotModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'staff': instance.staff,
  'date': instance.date,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'is_available': instance.isAvailable,
};
