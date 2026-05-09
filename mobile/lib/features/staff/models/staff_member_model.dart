import 'package:json_annotation/json_annotation.dart';

part 'staff_member_model.g.dart';

@JsonSerializable()
class StaffMemberModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'staff', 'coordinator', 'secretary'
  final String status; // 'active', 'inactive'
  final String? position;
  @JsonKey(name: 'work_schedule')
  final String? workSchedule;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const StaffMemberModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.position,
    this.workSchedule,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) =>
      _$StaffMemberModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffMemberModelToJson(this);

  bool get isActive => status == 'active';
}
