import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/client/services/chat_service.dart';
import 'package:frontend/features/client/services/document_service.dart';
import 'package:frontend/features/client/services/appointment_service.dart';

/// A mock DioClient that uses a custom interceptor to capture and respond to requests.
class _MockDioClient extends DioClient {
  final List<RequestOptions> capturedRequests = [];
  dynamic Function(RequestOptions)? onRequest;

  _MockDioClient() : super(storage: const FlutterSecureStorage()) {
    // Clear real interceptors and add our mock one
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        capturedRequests.add(options);
        final response = onRequest?.call(options);
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: response,
        ));
      },
    ));
  }
}

void main() {
  late _MockDioClient mockClient;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockClient = _MockDioClient();
  });

  group('ChatService calls correct API endpoints', () {
    test('user can fetch chat sessions from GET /chat-sessions', () async {
      mockClient.onRequest = (options) => [
            {
              'id': 'sess-001',
              'student_id': null,
              'whatsapp_phone': null,
              'status': 'active',
              'verification_state': null,
              'started_at': '2026-05-01T10:00:00.000Z',
              'ended_at': null,
              'updated_at': null,
              'message_count': 3,
            }
          ];

      final service = ChatService(client: mockClient);
      final sessions = await service.getSessions();

      expect(mockClient.capturedRequests, hasLength(1));
      expect(mockClient.capturedRequests.first.path, '/chat-sessions');
      expect(mockClient.capturedRequests.first.method, 'GET');
      expect(sessions, hasLength(1));
      expect(sessions.first.id, 'sess-001');
    });

    test('user can fetch sessions with status filter query param', () async {
      mockClient.onRequest = (options) => [];

      final service = ChatService(client: mockClient);
      await service.getSessions(status: 'active');

      expect(mockClient.capturedRequests.first.queryParameters['status'],
          'active');
    });

    test('user can fetch messages from GET /chat-sessions/{id}/messages',
        () async {
      mockClient.onRequest = (options) => [
            {
              'id': 'msg-001',
              'chat_session_id': 'sess-001',
              'role': 'user',
              'content': 'Hello',
              'media_type': null,
              'whatsapp_message_id': null,
              'created_at': '2026-05-01T10:00:00.000Z',
            }
          ];

      final service = ChatService(client: mockClient);
      final messages = await service.getMessages('sess-001');

      expect(mockClient.capturedRequests.first.path,
          '/chat-sessions/sess-001/messages');
      expect(messages, hasLength(1));
      expect(messages.first.content, 'Hello');
    });

    test('user can fetch action logs from GET /chat-sessions/{id}/action-logs',
        () async {
      mockClient.onRequest = (options) => [
            {
              'id': 'log-001',
              'chat_session_id': 'sess-001',
              'tool_name': 'get_grades',
              'input_params': <String, dynamic>{},
              'output_result': null,
              'reasoning': null,
              'latency_ms': 100,
              'retry': false,
              'status': 'success',
              'created_at': '2026-05-01T10:00:00.000Z',
            }
          ];

      final service = ChatService(client: mockClient);
      final logs = await service.getActionLogs('sess-001');

      expect(mockClient.capturedRequests.first.path,
          '/chat-sessions/sess-001/action-logs');
      expect(logs, hasLength(1));
      expect(logs.first.toolName, 'get_grades');
    });

    test('user can fetch sessions from envelope response format', () async {
      mockClient.onRequest = (options) => {
            'data': [
              {
                'id': 'sess-002',
                'student_id': null,
                'whatsapp_phone': null,
                'status': 'closed',
                'verification_state': null,
                'started_at': '2026-05-01T08:00:00.000Z',
                'ended_at': '2026-05-01T09:00:00.000Z',
                'updated_at': null,
                'message_count': null,
              }
            ]
          };

      final service = ChatService(client: mockClient);
      final sessions = await service.getSessions();

      expect(sessions, hasLength(1));
      expect(sessions.first.id, 'sess-002');
    });
  });

  group('DocumentService calls correct API endpoints', () {
    test('user can fetch documents from GET /documents', () async {
      mockClient.onRequest = (options) => [
            {
              'id': 'doc-001',
              'type': 'transcript',
              'status': 'ready',
              'file_url': 'https://example.com/doc.pdf',
              'notes': null,
              'requested_at': '2026-04-28T14:00:00.000Z',
              'completed_at': '2026-05-01T09:00:00.000Z',
            }
          ];

      final service = DocumentService(client: mockClient);
      final docs = await service.getDocuments();

      expect(mockClient.capturedRequests.first.path, '/documents');
      expect(mockClient.capturedRequests.first.method, 'GET');
      expect(docs, hasLength(1));
      expect(docs.first.type, 'transcript');
    });

    test('user can fetch documents with status filter', () async {
      mockClient.onRequest = (options) => [];

      final service = DocumentService(client: mockClient);
      await service.getDocuments(status: 'ready');

      expect(
          mockClient.capturedRequests.first.queryParameters['status'], 'ready');
    });

    test('user can fetch a single document from GET /documents/{id}',
        () async {
      mockClient.onRequest = (options) => {
            'id': 'doc-001',
            'type': 'transcript',
            'status': 'ready',
            'file_url': 'https://example.com/doc.pdf',
            'notes': null,
            'requested_at': '2026-04-28T14:00:00.000Z',
            'completed_at': '2026-05-01T09:00:00.000Z',
          };

      final service = DocumentService(client: mockClient);
      final doc = await service.getDocument('doc-001');

      expect(mockClient.capturedRequests.first.path, '/documents/doc-001');
      expect(doc.id, 'doc-001');
    });

    test('user can request a new document via POST /documents', () async {
      mockClient.onRequest = (options) => {
            'id': 'doc-new',
            'type': 'enrollment_proof',
            'status': 'requested',
            'file_url': null,
            'notes': 'Para estagio',
            'requested_at': '2026-05-01T12:00:00.000Z',
            'completed_at': null,
          };

      final service = DocumentService(client: mockClient);
      final doc = await service.requestDocument(
        type: 'enrollment_proof',
        notes: 'Para estagio',
      );

      expect(mockClient.capturedRequests.first.path, '/documents');
      expect(mockClient.capturedRequests.first.method, 'POST');
      expect(mockClient.capturedRequests.first.data['type'], 'enrollment_proof');
      expect(mockClient.capturedRequests.first.data['notes'], 'Para estagio');
      expect(doc.id, 'doc-new');
      expect(doc.status, 'requested');
    });

    test('user can request a document without notes', () async {
      mockClient.onRequest = (options) => {
            'id': 'doc-new2',
            'type': 'transcript',
            'status': 'requested',
            'file_url': null,
            'notes': null,
            'requested_at': '2026-05-01T12:00:00.000Z',
            'completed_at': null,
          };

      final service = DocumentService(client: mockClient);
      await service.requestDocument(type: 'transcript');

      expect(
          mockClient.capturedRequests.first.data.containsKey('notes'), isFalse);
    });
  });

  group('AppointmentService calls correct API endpoints', () {
    test('user can fetch appointments from GET /appointments', () async {
      mockClient.onRequest = (options) => [
            {
              'id': 'apt-001',
              'slot_id': 'slot-123',
              'reason': 'Reuniao com coordenador',
              'status': 'scheduled',
              'slot_date': '2026-05-03',
              'slot_start_time': '14:00',
              'end_time': '14:30',
              'created_at': '2026-05-01T10:00:00.000Z',
            }
          ];

      final service = AppointmentService(client: mockClient);
      final appointments = await service.getAppointments();

      expect(mockClient.capturedRequests.first.path, '/appointments');
      expect(mockClient.capturedRequests.first.method, 'GET');
      expect(appointments, hasLength(1));
      expect(appointments.first.reason, 'Reuniao com coordenador');
    });

    test('user can fetch appointments with status filter', () async {
      mockClient.onRequest = (options) => [];

      final service = AppointmentService(client: mockClient);
      await service.getAppointments(status: 'scheduled');

      expect(mockClient.capturedRequests.first.queryParameters['status'],
          'scheduled');
    });

    test('user can fetch appointments from envelope response format', () async {
      mockClient.onRequest = (options) => {
            'data': [
              {
                'id': 'apt-002',
                'slot_id': null,
                'reason': 'Entrega de documento',
                'status': 'completed',
                'slot_date': '2026-04-25',
                'slot_start_time': '10:00',
                'end_time': '10:30',
                'created_at': '2026-04-20T08:00:00.000Z',
              }
            ]
          };

      final service = AppointmentService(client: mockClient);
      final appointments = await service.getAppointments();

      expect(appointments, hasLength(1));
      expect(appointments.first.id, 'apt-002');
    });
  });
}
