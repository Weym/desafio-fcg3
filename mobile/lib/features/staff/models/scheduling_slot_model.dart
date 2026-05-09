import 'package:json_annotation/json_annotation.dart';

part 'scheduling_slot_model.g.dart';

@JsonSerializable()
class SlotStaffInfo {
  final String id;
  final String name;

  const SlotStaffInfo({required this.id, required this.name});

  factory SlotStaffInfo.fromJson(Map<String, dynamic> json) =>
      _$SlotStaffInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SlotStaffInfoToJson(this);
}

@JsonSerializable()
class SchedulingSlotModel {
  final String id;
  final SlotStaffInfo? staff;
  final String date;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String endTime;
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  const SchedulingSlotModel({
    required this.id,
    this.staff,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory SchedulingSlotModel.fromJson(Map<String, dynamic> json) =>
      _$SchedulingSlotModelFromJson(json);
  Map<String, dynamic> toJson() => _$SchedulingSlotModelToJson(this);
}
