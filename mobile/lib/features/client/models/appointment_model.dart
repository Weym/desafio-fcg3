import 'package:json_annotation/json_annotation.dart';

part 'appointment_model.g.dart';

@JsonSerializable()
class AppointmentModel {
  final String id;
  @JsonKey(name: 'slot_id')
  final String? slotId;
  final String reason;
  final String status; // 'scheduled', 'completed', 'cancelled', 'no_show'
  final String? date;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'end_time')
  final String? endTime;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    this.slotId,
    required this.reason,
    required this.status,
    this.date,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$AppointmentModelFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentModelToJson(this);

  bool get isUpcoming => status == 'scheduled';
}
