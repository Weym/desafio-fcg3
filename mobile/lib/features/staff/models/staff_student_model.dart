import 'package:json_annotation/json_annotation.dart';

part 'staff_student_model.g.dart';

@JsonSerializable()
class StaffStudentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  @JsonKey(name: 'registration_number')
  final String? ra;
  final int? semester;
  final String status; // 'active' or 'inactive'
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const StaffStudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.ra,
    this.semester,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status == 'active';

  /// Display period as string for UI
  String? get period => semester?.toString();

  factory StaffStudentModel.fromJson(Map<String, dynamic> json) =>
      _$StaffStudentModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffStudentModelToJson(this);
}
