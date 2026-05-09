// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentPeriodInfo _$EnrollmentPeriodInfoFromJson(
  Map<String, dynamic> json,
) => EnrollmentPeriodInfo(
  name: json['name'] as String,
  isActive: json['is_active'] as bool,
  daysRemaining: (json['days_remaining'] as num?)?.toInt(),
);

Map<String, dynamic> _$EnrollmentPeriodInfoToJson(
  EnrollmentPeriodInfo instance,
) => <String, dynamic>{
  'name': instance.name,
  'is_active': instance.isActive,
  'days_remaining': instance.daysRemaining,
};

StaffDashboardModel _$StaffDashboardModelFromJson(Map<String, dynamic> json) =>
    StaffDashboardModel(
      totalStudents: (json['total_students'] as num).toInt(),
      activeEnrollments: (json['active_enrollments'] as num).toInt(),
      pendingDocuments: (json['pending_documents'] as num).toInt(),
      upcomingAppointments: (json['upcoming_appointments'] as num).toInt(),
      activeChatSessions: (json['active_chat_sessions'] as num).toInt(),
      enrollmentPeriod: json['enrollment_period'] == null
          ? null
          : EnrollmentPeriodInfo.fromJson(
              json['enrollment_period'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$StaffDashboardModelToJson(
  StaffDashboardModel instance,
) => <String, dynamic>{
  'total_students': instance.totalStudents,
  'active_enrollments': instance.activeEnrollments,
  'pending_documents': instance.pendingDocuments,
  'upcoming_appointments': instance.upcomingAppointments,
  'active_chat_sessions': instance.activeChatSessions,
  'enrollment_period': instance.enrollmentPeriod,
};
