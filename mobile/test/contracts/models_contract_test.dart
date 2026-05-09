// Phase 12, Plan 02 — GAP-12-02-B: Domain model contract tests.
//
// Verifies that every Dart domain model listed in plan 12-02 parses the
// canonical backend JSON shape without throwing, and that nullable fields
// accept both values and nulls.
//
// Backend is source of truth (D-02). JSON literals here mirror the fields
// observed in the backend Pydantic schemas and seeded fixtures — they are
// the contract the Flutter app depends on.
//
// No network or Docker dependency — pure JSON parsing. Run with:
//   cd mobile && flutter test test/contracts/

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/client/models/action_log_model.dart';
import 'package:frontend/features/client/models/appointment_model.dart';
import 'package:frontend/features/client/models/chat_message_model.dart';
import 'package:frontend/features/client/models/chat_session_model.dart';
import 'package:frontend/features/client/models/document_model.dart';
import 'package:frontend/features/staff/models/staff_dashboard_model.dart';

void main() {
  group('DocumentModel contract', () {
    test('parses canonical document JSON including timestamps', () {
      final doc = DocumentModel.fromJson(const {
        'id': '11111111-1111-1111-1111-111111111111',
        'type': 'enrollment_proof',
        'status': 'processing',
        'file_url': null,
        'notes': 'Algum comprovante ai',
        'requested_at': '2026-05-03T12:00:00Z',
        'completed_at': null,
      });

      expect(doc.id, '11111111-1111-1111-1111-111111111111');
      expect(doc.type, 'enrollment_proof');
      expect(doc.status, 'processing');
      expect(doc.fileUrl, isNull);
      expect(doc.notes, 'Algum comprovante ai');
      expect(doc.requestedAt.isUtc, isTrue);
      expect(doc.completedAt, isNull);
      expect(doc.isPending, isTrue);
      expect(doc.isDownloadable, isFalse);
    });

    test('parses ready document with file_url and completed_at populated', () {
      final doc = DocumentModel.fromJson(const {
        'id': '22222222-2222-2222-2222-222222222222',
        'type': 'transcript',
        'status': 'ready',
        'file_url': 'https://storage.example.com/docs/x.pdf',
        'notes': null,
        'requested_at': '2026-05-01T08:00:00Z',
        'completed_at': '2026-05-04T15:30:00Z',
      });

      expect(doc.fileUrl, 'https://storage.example.com/docs/x.pdf');
      expect(doc.completedAt, isNotNull);
      expect(doc.isDownloadable, isTrue);
    });
  });

  group('ChatSessionModel contract', () {
    test('parses full session JSON with all optional fields present', () {
      final session = ChatSessionModel.fromJson(const {
        'id': 'sess-1',
        'student_id': 'stu-1',
        'whatsapp_phone': '5583998257544',
        'status': 'active',
        'verification_state': 'verified',
        'started_at': '2026-05-06T10:00:00Z',
        'ended_at': null,
        'updated_at': '2026-05-06T10:30:00Z',
        'message_count': 12,
      });

      expect(session.id, 'sess-1');
      expect(session.studentId, 'stu-1');
      expect(session.whatsappPhone, '5583998257544');
      expect(session.status, 'active');
      expect(session.isActive, isTrue);
      expect(session.verificationState, 'verified');
      expect(session.endedAt, isNull);
      expect(session.messageCount, 12);
    });

    test('parses minimal session JSON where all optionals are null', () {
      final session = ChatSessionModel.fromJson(const {
        'id': 'sess-2',
        'student_id': null,
        'whatsapp_phone': null,
        'status': 'closed',
        'verification_state': null,
        'started_at': '2026-05-06T10:00:00Z',
        'ended_at': '2026-05-06T11:00:00Z',
        'updated_at': null,
        'message_count': null,
      });

      expect(session.studentId, isNull);
      expect(session.whatsappPhone, isNull);
      expect(session.status, 'closed');
      expect(session.isActive, isFalse);
      expect(session.messageCount, isNull);
    });
  });

  group('ChatMessageModel contract', () {
    test('parses user message with media_type null', () {
      final msg = ChatMessageModel.fromJson(const {
        'id': 'msg-1',
        'chat_session_id': 'sess-1',
        'role': 'user',
        'content': 'Qual meu CRA?',
        'media_type': null,
        'whatsapp_message_id': 'wa-123',
        'created_at': '2026-05-06T10:05:00Z',
      });

      expect(msg.id, 'msg-1');
      expect(msg.chatSessionId, 'sess-1');
      expect(msg.role, 'user');
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
      expect(msg.content, 'Qual meu CRA?');
      expect(msg.mediaType, isNull);
      expect(msg.whatsappMessageId, 'wa-123');
    });

    test('parses assistant message with no whatsapp_message_id', () {
      final msg = ChatMessageModel.fromJson(const {
        'id': 'msg-2',
        'chat_session_id': null,
        'role': 'assistant',
        'content': 'Seu CRA é 8.5',
        'media_type': null,
        'whatsapp_message_id': null,
        'created_at': '2026-05-06T10:05:30Z',
      });
      expect(msg.isAssistant, isTrue);
      expect(msg.chatSessionId, isNull);
      expect(msg.whatsappMessageId, isNull);
    });
  });

  group('AppointmentModel contract', () {
    test('parses appointment with slot metadata present', () {
      final appt = AppointmentModel.fromJson(const {
        'id': 'appt-1',
        'slot_id': 'slot-1',
        'reason': 'Dúvidas sobre plano de estudos',
        'status': 'scheduled',
        'slot_date': '2026-05-07',
        'slot_start_time': '09:00:00',
        'end_time': '10:00:00',
        'created_at': '2026-05-06T08:00:00Z',
      });

      expect(appt.id, 'appt-1');
      expect(appt.slotId, 'slot-1');
      expect(appt.reason, 'Dúvidas sobre plano de estudos');
      expect(appt.status, 'scheduled');
      expect(appt.isUpcoming, isTrue);
      expect(appt.slotDate, '2026-05-07');
      expect(appt.slotStartTime, '09:00:00');
      expect(appt.endTime, '10:00:00');
    });

    test('parses cancelled appointment with slot metadata null', () {
      final appt = AppointmentModel.fromJson(const {
        'id': 'appt-2',
        'slot_id': null,
        'reason': 'Atendimento',
        'status': 'cancelled',
        'slot_date': null,
        'slot_start_time': null,
        'end_time': null,
        'created_at': '2026-05-06T08:00:00Z',
      });

      expect(appt.slotId, isNull);
      expect(appt.status, 'cancelled');
      expect(appt.isUpcoming, isFalse);
    });
  });

  group('ActionLogModel contract', () {
    test('parses MCP action log with successful output', () {
      final log = ActionLogModel.fromJson(const {
        'id': 'log-1',
        'chat_session_id': 'sess-1',
        'tool_name': 'get_grades',
        'input_params': {'semester': '2026.1'},
        'output_result': {'grades': []},
        'reasoning': 'Student asked about grades',
        'latency_ms': 420,
        'retry': false,
        'status': 'success',
        'created_at': '2026-05-06T10:05:00Z',
      });

      expect(log.id, 'log-1');
      expect(log.chatSessionId, 'sess-1');
      expect(log.toolName, 'get_grades');
      expect(log.inputParams, {'semester': '2026.1'});
      expect(log.outputResult, {'grades': []});
      expect(log.reasoning, 'Student asked about grades');
      expect(log.latencyMs, 420);
      expect(log.retry, isFalse);
      expect(log.status, 'success');
      expect(log.isError, isFalse);
    });

    test('parses error action log with nullable fields null', () {
      final log = ActionLogModel.fromJson(const {
        'id': 'log-2',
        'chat_session_id': null,
        'tool_name': 'unknown_tool',
        'input_params': <String, dynamic>{},
        'output_result': null,
        'reasoning': null,
        'latency_ms': null,
        'retry': true,
        'status': 'error',
        'created_at': '2026-05-06T10:05:00Z',
      });

      expect(log.chatSessionId, isNull);
      expect(log.outputResult, isNull);
      expect(log.reasoning, isNull);
      expect(log.latencyMs, isNull);
      expect(log.retry, isTrue);
      expect(log.isError, isTrue);
    });
  });

  group('StaffDashboardModel contract', () {
    test('parses dashboard KPI JSON with active enrollment period', () {
      final dashboard = StaffDashboardModel.fromJson(const {
        'total_students': 6,
        'active_enrollments': 5,
        'pending_documents': 4,
        'upcoming_appointments': 2,
        'active_chat_sessions': 0,
        'enrollment_period': {
          'name': '2026.1 - Matrícula',
          'is_active': true,
          'days_remaining': 15,
        },
      });

      expect(dashboard.totalStudents, 6);
      expect(dashboard.activeEnrollments, 5);
      expect(dashboard.pendingDocuments, 4);
      expect(dashboard.upcomingAppointments, 2);
      expect(dashboard.activeChatSessions, 0);
      expect(dashboard.enrollmentPeriod, isNotNull);
      expect(dashboard.enrollmentPeriod!.name, '2026.1 - Matrícula');
      expect(dashboard.enrollmentPeriod!.isActive, isTrue);
      expect(dashboard.enrollmentPeriod!.daysRemaining, 15);
    });

    test('parses dashboard with null enrollment_period (no active period)', () {
      final dashboard = StaffDashboardModel.fromJson(const {
        'total_students': 0,
        'active_enrollments': 0,
        'pending_documents': 0,
        'upcoming_appointments': 0,
        'active_chat_sessions': 0,
        'enrollment_period': null,
      });

      expect(dashboard.totalStudents, 0);
      expect(dashboard.enrollmentPeriod, isNull);
    });

    test('parses EnrollmentPeriodInfo with days_remaining null', () {
      final period = EnrollmentPeriodInfo.fromJson(const {
        'name': 'Inactive Period',
        'is_active': false,
        'days_remaining': null,
      });
      expect(period.name, 'Inactive Period');
      expect(period.isActive, isFalse);
      expect(period.daysRemaining, isNull);
    });
  });
}
