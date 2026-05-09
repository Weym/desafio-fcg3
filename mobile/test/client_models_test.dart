import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/client/models/chat_session_model.dart';
import 'package:frontend/features/client/models/chat_message_model.dart';
import 'package:frontend/features/client/models/action_log_model.dart';
import 'package:frontend/features/client/models/document_model.dart';
import 'package:frontend/features/client/models/appointment_model.dart';

void main() {
  group('ChatSessionModel JSON serialization', () {
    test('user can deserialize a chat session from API response', () {
      final json = {
        'id': 'sess-001',
        'student_id': 'stu-123',
        'whatsapp_phone': '+5521999999999',
        'status': 'active',
        'verification_state': 'verified',
        'started_at': '2026-05-01T10:30:00.000Z',
        'ended_at': null,
        'updated_at': '2026-05-01T11:00:00.000Z',
        'message_count': 5,
      };

      final model = ChatSessionModel.fromJson(json);

      expect(model.id, 'sess-001');
      expect(model.studentId, 'stu-123');
      expect(model.whatsappPhone, '+5521999999999');
      expect(model.status, 'active');
      expect(model.startedAt, DateTime.utc(2026, 5, 1, 10, 30));
      expect(model.endedAt, isNull);
      expect(model.messageCount, 5);
      expect(model.isActive, isTrue);
    });

    test('user can serialize a chat session back to JSON round-trip', () {
      final original = {
        'id': 'sess-002',
        'student_id': null,
        'whatsapp_phone': null,
        'status': 'closed',
        'verification_state': null,
        'started_at': '2026-04-20T08:00:00.000Z',
        'ended_at': '2026-04-20T09:15:00.000Z',
        'updated_at': null,
        'message_count': null,
      };

      final model = ChatSessionModel.fromJson(original);
      final serialized = model.toJson();

      expect(serialized['id'], 'sess-002');
      expect(serialized['status'], 'closed');
      expect(serialized['started_at'], isNotNull);
      expect(serialized['ended_at'], isNotNull);
      expect(model.isActive, isFalse);
    });
  });

  group('ChatMessageModel JSON serialization', () {
    test('user can deserialize a user message from API', () {
      final json = {
        'id': 'msg-001',
        'chat_session_id': 'sess-001',
        'role': 'user',
        'content': 'Quero solicitar meu historico',
        'media_type': null,
        'whatsapp_message_id': 'wamid.123',
        'created_at': '2026-05-01T10:31:00.000Z',
      };

      final model = ChatMessageModel.fromJson(json);

      expect(model.id, 'msg-001');
      expect(model.role, 'user');
      expect(model.content, 'Quero solicitar meu historico');
      expect(model.isUser, isTrue);
      expect(model.isAssistant, isFalse);
    });

    test('user can deserialize an assistant message from API', () {
      final json = {
        'id': 'msg-002',
        'chat_session_id': 'sess-001',
        'role': 'assistant',
        'content': 'Vou solicitar seu historico escolar.',
        'media_type': null,
        'whatsapp_message_id': null,
        'created_at': '2026-05-01T10:31:30.000Z',
      };

      final model = ChatMessageModel.fromJson(json);

      expect(model.isUser, isFalse);
      expect(model.isAssistant, isTrue);
    });

    test('user can round-trip serialize a message', () {
      final json = {
        'id': 'msg-003',
        'chat_session_id': 'sess-001',
        'role': 'user',
        'content': 'Obrigado!',
        'media_type': 'image',
        'whatsapp_message_id': null,
        'created_at': '2026-05-01T10:32:00.000Z',
      };

      final model = ChatMessageModel.fromJson(json);
      final serialized = model.toJson();

      expect(serialized['role'], 'user');
      expect(serialized['content'], 'Obrigado!');
      expect(serialized['media_type'], 'image');
    });
  });

  group('ActionLogModel JSON serialization', () {
    test('user can deserialize a successful action log', () {
      final json = {
        'id': 'log-001',
        'chat_session_id': 'sess-001',
        'tool_name': 'request_document',
        'input_params': {'type': 'transcript'},
        'output_result': {'document_id': 'doc-001', 'status': 'requested'},
        'reasoning': 'User asked for transcript',
        'latency_ms': 250,
        'retry': false,
        'status': 'success',
        'created_at': '2026-05-01T10:32:00.000Z',
      };

      final model = ActionLogModel.fromJson(json);

      expect(model.id, 'log-001');
      expect(model.toolName, 'request_document');
      expect(model.inputParams, {'type': 'transcript'});
      expect(model.outputResult, isNotNull);
      expect(model.latencyMs, 250);
      expect(model.retry, isFalse);
      expect(model.status, 'success');
      expect(model.isError, isFalse);
    });

    test('user can deserialize an error action log', () {
      final json = {
        'id': 'log-002',
        'chat_session_id': 'sess-001',
        'tool_name': 'get_grades',
        'input_params': <String, dynamic>{},
        'output_result': null,
        'reasoning': null,
        'latency_ms': null,
        'retry': true,
        'status': 'error',
        'created_at': '2026-05-01T10:33:00.000Z',
      };

      final model = ActionLogModel.fromJson(json);

      expect(model.isError, isTrue);
      expect(model.retry, isTrue);
      expect(model.outputResult, isNull);
    });

    test('user can round-trip serialize an action log', () {
      final json = {
        'id': 'log-003',
        'chat_session_id': null,
        'tool_name': 'list_documents',
        'input_params': {'status': 'ready'},
        'output_result': {'count': 2},
        'reasoning': null,
        'latency_ms': 100,
        'retry': false,
        'status': 'success',
        'created_at': '2026-05-01T10:34:00.000Z',
      };

      final model = ActionLogModel.fromJson(json);
      final serialized = model.toJson();

      expect(serialized['tool_name'], 'list_documents');
      expect(serialized['input_params'], {'status': 'ready'});
      expect(serialized['latency_ms'], 100);
    });
  });

  group('DocumentModel JSON serialization', () {
    test('user can deserialize a ready document with file URL', () {
      final json = {
        'id': 'doc-001',
        'type': 'transcript',
        'status': 'ready',
        'file_url': 'https://storage.example.com/docs/doc-001.pdf',
        'notes': 'Historico completo',
        'requested_at': '2026-04-28T14:00:00.000Z',
        'completed_at': '2026-05-01T09:00:00.000Z',
      };

      final model = DocumentModel.fromJson(json);

      expect(model.id, 'doc-001');
      expect(model.type, 'transcript');
      expect(model.status, 'ready');
      expect(model.fileUrl, contains('doc-001.pdf'));
      expect(model.isDownloadable, isTrue);
      expect(model.isPending, isFalse);
    });

    test('user can identify a pending document', () {
      final json = {
        'id': 'doc-002',
        'type': 'enrollment_proof',
        'status': 'processing',
        'file_url': null,
        'notes': null,
        'requested_at': '2026-05-01T10:00:00.000Z',
        'completed_at': null,
      };

      final model = DocumentModel.fromJson(json);

      expect(model.isPending, isTrue);
      expect(model.isDownloadable, isFalse);
    });

    test('user can identify a delivered document as downloadable', () {
      final json = {
        'id': 'doc-003',
        'type': 'certificate',
        'status': 'delivered',
        'file_url': 'https://storage.example.com/docs/doc-003.pdf',
        'notes': null,
        'requested_at': '2026-04-10T08:00:00.000Z',
        'completed_at': '2026-04-15T16:00:00.000Z',
      };

      final model = DocumentModel.fromJson(json);

      expect(model.isDownloadable, isTrue);
      expect(model.isPending, isFalse);
    });

    test('user can round-trip serialize a document', () {
      final json = {
        'id': 'doc-004',
        'type': 'declaration',
        'status': 'requested',
        'file_url': null,
        'notes': 'Para estagio',
        'requested_at': '2026-05-01T10:00:00.000Z',
        'completed_at': null,
      };

      final model = DocumentModel.fromJson(json);
      final serialized = model.toJson();

      expect(serialized['type'], 'declaration');
      expect(serialized['status'], 'requested');
      expect(serialized['notes'], 'Para estagio');
      expect(serialized['file_url'], isNull);
    });
  });

  group('AppointmentModel JSON serialization', () {
    test('user can deserialize a scheduled appointment', () {
      final json = {
        'id': 'apt-001',
        'slot_id': 'slot-123',
        'reason': 'Reuniao com coordenador',
        'status': 'scheduled',
        'slot_date': '2026-05-03',
        'slot_start_time': '14:00',
        'end_time': '14:30',
        'created_at': '2026-05-01T10:00:00.000Z',
      };

      final model = AppointmentModel.fromJson(json);

      expect(model.id, 'apt-001');
      expect(model.slotId, 'slot-123');
      expect(model.reason, 'Reuniao com coordenador');
      expect(model.status, 'scheduled');
      expect(model.slotDate, '2026-05-03');
      expect(model.slotStartTime, '14:00');
      expect(model.isUpcoming, isTrue);
    });

    test('user can identify a completed appointment as not upcoming', () {
      final json = {
        'id': 'apt-002',
        'slot_id': null,
        'reason': 'Entrega de documento',
        'status': 'completed',
        'slot_date': '2026-04-25',
        'slot_start_time': '10:00',
        'end_time': '10:30',
        'created_at': '2026-04-20T08:00:00.000Z',
      };

      final model = AppointmentModel.fromJson(json);

      expect(model.isUpcoming, isFalse);
    });

    test('user can round-trip serialize an appointment', () {
      final json = {
        'id': 'apt-003',
        'slot_id': 'slot-456',
        'reason': 'Matricula presencial',
        'status': 'cancelled',
        'slot_date': null,
        'slot_start_time': null,
        'end_time': null,
        'created_at': '2026-05-01T12:00:00.000Z',
      };

      final model = AppointmentModel.fromJson(json);
      final serialized = model.toJson();

      expect(serialized['reason'], 'Matricula presencial');
      expect(serialized['status'], 'cancelled');
      expect(serialized['slot_date'], isNull);
      expect(model.isUpcoming, isFalse);
    });
  });
}
