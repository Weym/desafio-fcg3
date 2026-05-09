import 'package:json_annotation/json_annotation.dart';

part 'staff_student_model.g.dart';

@JsonSerializable()
class StaffStudentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? ra;
  final String? period;
  final String? campus;
  final String status; // 'active' or 'inactive'
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const StaffStudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.ra,
    this.period,
    this.campus,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status == 'active';

  factory StaffStudentModel.fromJson(Map<String, dynamic> json) =>
      _$StaffStudentModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffStudentModelToJson(this);
}
