import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/staff/models/staff_dashboard_model.dart';
import 'package:frontend/features/staff/models/scheduling_slot_model.dart';
import 'package:frontend/features/staff/models/student_summary_model.dart';

void main() {
  group('StaffDashboardModel JSON serialization', () {
    test('fromJson creates model with all KPI fields', () {
      final json = {
        'total_students': 120,
        'active_enrollments': 95,
        'pending_documents': 12,
        'upcoming_appointments': 5,
        'active_chat_sessions': 3,
        'enrollment_period': {
          'name': '2026.1 - Primeiro Semestre',
          'is_active': true,
          'days_remaining': 15,
        },
      };

      final model = StaffDashboardModel.fromJson(json);

      expect(model.totalStudents, 120);
      expect(model.activeEnrollments, 95);
      expect(model.pendingDocuments, 12);
      expect(model.upcomingAppointments, 5);
      expect(model.activeChatSessions, 3);
      expect(model.enrollmentPeriod, isNotNull);
      expect(model.enrollmentPeriod!.name, '2026.1 - Primeiro Semestre');
      expect(model.enrollmentPeriod!.isActive, true);
      expect(model.enrollmentPeriod!.daysRemaining, 15);
    });

    test('fromJson handles null enrollment period', () {
      final json = {
        'total_students': 50,
        'active_enrollments': 30,
        'pending_documents': 0,
        'upcoming_appointments': 0,
        'active_chat_sessions': 0,
        'enrollment_period': null,
      };

      final model = StaffDashboardModel.fromJson(json);

      expect(model.totalStudents, 50);
      expect(model.enrollmentPeriod, isNull);
    });

    test('toJson produces correct snake_case keys', () {
      const model = StaffDashboardModel(
        totalStudents: 100,
        activeEnrollments: 80,
        pendingDocuments: 5,
        upcomingAppointments: 2,
        activeChatSessions: 1,
        enrollmentPeriod: EnrollmentPeriodInfo(
          name: 'Test Period',
          isActive: true,
          daysRemaining: 10,
        ),
      );

      final json = model.toJson();

      expect(json['total_students'], 100);
      expect(json['active_enrollments'], 80);
      expect(json['pending_documents'], 5);
      expect(json['upcoming_appointments'], 2);
      expect(json['active_chat_sessions'], 1);
      expect(json['enrollment_period'], isNotNull);
      expect(json['enrollment_period']['is_active'], true);
      expect(json['enrollment_period']['days_remaining'], 10);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = {
        'total_students': 200,
        'active_enrollments': 150,
        'pending_documents': 20,
        'upcoming_appointments': 8,
        'active_chat_sessions': 4,
        'enrollment_period': {
          'name': 'Periodo Teste',
          'is_active': false,
          'days_remaining': null,
        },
      };

      final model = StaffDashboardModel.fromJson(original);
      final restored = model.toJson();

      expect(restored['total_students'], original['total_students']);
      expect(restored['active_enrollments'], original['active_enrollments']);
      expect(restored['pending_documents'], original['pending_documents']);
      expect(
          restored['upcoming_appointments'], original['upcoming_appointments']);
      expect(
          restored['active_chat_sessions'], original['active_chat_sessions']);
    });
  });

  group('EnrollmentPeriodInfo JSON serialization', () {
    test('fromJson creates model with all fields', () {
      final json = {
        'name': '2026.2',
        'is_active': true,
        'days_remaining': 30,
      };

      final model = EnrollmentPeriodInfo.fromJson(json);

      expect(model.name, '2026.2');
      expect(model.isActive, true);
      expect(model.daysRemaining, 30);
    });

    test('fromJson handles null days_remaining', () {
      final json = {
        'name': 'Closed Period',
        'is_active': false,
        'days_remaining': null,
      };

      final model = EnrollmentPeriodInfo.fromJson(json);

      expect(model.name, 'Closed Period');
      expect(model.isActive, false);
      expect(model.daysRemaining, isNull);
    });
  });

  group('SchedulingSlotModel JSON serialization', () {
    test('fromJson creates model with all fields including staff', () {
      final json = {
        'id': 'slot-uuid-123',
        'staff': {'id': 'staff-uuid', 'name': 'Dr. Carlos'},
        'date': '2026-05-10',
        'start_time': '09:00',
        'end_time': '09:30',
        'is_available': true,
      };

      final model = SchedulingSlotModel.fromJson(json);

      expect(model.id, 'slot-uuid-123');
      expect(model.staff, isNotNull);
      expect(model.staff!.id, 'staff-uuid');
      expect(model.staff!.name, 'Dr. Carlos');
      expect(model.date, '2026-05-10');
      expect(model.startTime, '09:00');
      expect(model.endTime, '09:30');
      expect(model.isAvailable, true);
    });

    test('fromJson handles null staff', () {
      final json = {
        'id': 'slot-uuid-456',
        'staff': null,
        'date': '2026-06-01',
        'start_time': '14:00',
        'end_time': '14:30',
        'is_available': false,
      };

      final model = SchedulingSlotModel.fromJson(json);

      expect(model.id, 'slot-uuid-456');
      expect(model.staff, isNull);
      expect(model.isAvailable, false);
    });

    test('toJson produces correct snake_case keys', () {
      const model = SchedulingSlotModel(
        id: 'test-id',
        staff: SlotStaffInfo(id: 'staff-1', name: 'Ana'),
        date: '2026-07-15',
        startTime: '10:00',
        endTime: '10:45',
        isAvailable: true,
      );

      final json = model.toJson();

      expect(json['id'], 'test-id');
      expect(json['staff']['id'], 'staff-1');
      expect(json['staff']['name'], 'Ana');
      expect(json['date'], '2026-07-15');
      expect(json['start_time'], '10:00');
      expect(json['end_time'], '10:45');
      expect(json['is_available'], true);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = {
        'id': 'roundtrip-id',
        'staff': {'id': 's1', 'name': 'Teste'},
        'date': '2026-01-01',
        'start_time': '08:00',
        'end_time': '08:30',
        'is_available': true,
      };

      final model = SchedulingSlotModel.fromJson(original);
      final restored = model.toJson();

      expect(restored['id'], original['id']);
      expect(restored['date'], original['date']);
      expect(restored['start_time'], original['start_time']);
      expect(restored['end_time'], original['end_time']);
      expect(restored['is_available'], original['is_available']);
    });
  });

  group('SlotStaffInfo JSON serialization', () {
    test('fromJson creates model', () {
      final json = {'id': 'abc-123', 'name': 'Staff Member'};
      final model = SlotStaffInfo.fromJson(json);

      expect(model.id, 'abc-123');
      expect(model.name, 'Staff Member');
    });

    test('toJson produces correct output', () {
      const model = SlotStaffInfo(id: 'x', name: 'Y');
      final json = model.toJson();

      expect(json['id'], 'x');
      expect(json['name'], 'Y');
    });
  });

  group('StudentSummaryModel JSON serialization', () {
    test('fromJson creates model with all fields', () {
      final json = {
        'id': 'student-uuid-789',
        'name': 'Maria Silva',
        'email': 'maria@uni.edu',
        'registration_number': 'MAT2024001',
        'semester': 4,
        'status': 'active',
      };

      final model = StudentSummaryModel.fromJson(json);

      expect(model.id, 'student-uuid-789');
      expect(model.name, 'Maria Silva');
      expect(model.email, 'maria@uni.edu');
      expect(model.registrationNumber, 'MAT2024001');
      expect(model.semester, 4);
      expect(model.status, 'active');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'student-uuid-000',
        'name': 'Pedro',
        'email': 'pedro@test.edu',
        'registration_number': null,
        'semester': null,
        'status': 'inactive',
      };

      final model = StudentSummaryModel.fromJson(json);

      expect(model.id, 'student-uuid-000');
      expect(model.name, 'Pedro');
      expect(model.registrationNumber, isNull);
      expect(model.semester, isNull);
      expect(model.status, 'inactive');
    });

    test('toJson produces correct snake_case keys', () {
      const model = StudentSummaryModel(
        id: 'id-1',
        name: 'Test Name',
        email: 'test@test.com',
        registrationNumber: 'REG001',
        semester: 6,
        status: 'active',
      );

      final json = model.toJson();

      expect(json['id'], 'id-1');
      expect(json['name'], 'Test Name');
      expect(json['email'], 'test@test.com');
      expect(json['registration_number'], 'REG001');
      expect(json['semester'], 6);
      expect(json['status'], 'active');
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = {
        'id': 'rtrip-id',
        'name': 'Roundtrip Student',
        'email': 'round@test.edu',
        'registration_number': 'RT001',
        'semester': 2,
        'status': 'active',
      };

      final model = StudentSummaryModel.fromJson(original);
      final restored = model.toJson();

      expect(restored['id'], original['id']);
      expect(restored['name'], original['name']);
      expect(restored['email'], original['email']);
      expect(restored['registration_number'], original['registration_number']);
      expect(restored['semester'], original['semester']);
      expect(restored['status'], original['status']);
    });
  });
}
