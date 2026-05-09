import 'package:json_annotation/json_annotation.dart';

part 'student_summary_model.g.dart';

@JsonSerializable()
class StudentSummaryModel {
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'registration_number')
  final String? registrationNumber;
  final int? semester;
  final String status;

  const StudentSummaryModel({
    required this.id,
    required this.name,
    required this.email,
    this.registrationNumber,
    this.semester,
    required this.status,
  });

  factory StudentSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$StudentSummaryModelFromJson(json);
  Map<String, dynamic> toJson() => _$StudentSummaryModelToJson(this);
}
