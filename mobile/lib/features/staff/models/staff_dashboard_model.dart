import 'package:json_annotation/json_annotation.dart';

part 'staff_dashboard_model.g.dart';

@JsonSerializable()
class EnrollmentPeriodInfo {
  final String name;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'days_remaining')
  final int? daysRemaining;

  const EnrollmentPeriodInfo({
    required this.name,
    required this.isActive,
    this.daysRemaining,
  });

  factory EnrollmentPeriodInfo.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentPeriodInfoFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentPeriodInfoToJson(this);
}

@JsonSerializable()
class StaffDashboardModel {
  @JsonKey(name: 'total_students')
  final int totalStudents;
  @JsonKey(name: 'active_enrollments')
  final int activeEnrollments;
  @JsonKey(name: 'pending_documents')
  final int pendingDocuments;
  @JsonKey(name: 'upcoming_appointments')
  final int upcomingAppointments;
  @JsonKey(name: 'active_chat_sessions')
  final int activeChatSessions;
  @JsonKey(name: 'enrollment_period')
  final EnrollmentPeriodInfo? enrollmentPeriod;

  const StaffDashboardModel({
    required this.totalStudents,
    required this.activeEnrollments,
    required this.pendingDocuments,
    required this.upcomingAppointments,
    required this.activeChatSessions,
    this.enrollmentPeriod,
  });

  factory StaffDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$StaffDashboardModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffDashboardModelToJson(this);
}
