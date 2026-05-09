import 'package:json_annotation/json_annotation.dart';

part 'appointment_model.g.dart';

@JsonSerializable()
class AppointmentModel {
  final String id;
  @JsonKey(name: 'slot_id')
  final String? slotId;
  final String reason;
  final String status; // 'scheduled', 'completed', 'cancelled', 'no_show'
  @JsonKey(name: 'slot_date')
  final String? slotDate;
  @JsonKey(name: 'slot_start_time')
  final String? slotStartTime;
  @JsonKey(name: 'end_time')
  final String? endTime;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'student_name')
  final String? studentName;
  @JsonKey(name: 'student_ra')
  final String? studentRa;
  @JsonKey(name: 'resource_name')
  final String? resourceName;

  const AppointmentModel({
    required this.id,
    this.slotId,
    required this.reason,
    required this.status,
    this.slotDate,
    this.slotStartTime,
    this.endTime,
    required this.createdAt,
    this.studentName,
    this.studentRa,
    this.resourceName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$AppointmentModelFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentModelToJson(this);

  bool get isUpcoming => status == 'scheduled';
}
