import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  @JsonKey(readValue: _readRole)
  final String role; // 'student', 'staff', or 'provider'
  final String? phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool get isStudent => role == 'student';
  bool get isStaff => role == 'staff';
  bool get isProvider => role == 'provider';
  bool get isStaffOrProvider => isStaff || isProvider;
}

Object? _readRole(Map json, String key) => json['role'] ?? json['type'];
