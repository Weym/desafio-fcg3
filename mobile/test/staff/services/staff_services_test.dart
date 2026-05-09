import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/staff/services/staff_dashboard_service.dart';
import 'package:frontend/features/staff/services/staff_schedule_service.dart';
import 'package:frontend/features/staff/services/staff_document_service.dart';
import 'package:frontend/features/staff/services/staff_chat_service.dart';

/// Interceptor that captures request info and returns mock responses.
class _MockInterceptor extends Interceptor {
  final List<RequestOptions> capturedRequests = [];
  dynamic Function(RequestOptions options)? responseFactory;

  _MockInterceptor({this.responseFactory});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    capturedRequests.add(options);
    final data = responseFactory?.call(options) ?? {};
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: data,
    ));
  }
}

/// Creates a DioClient for testing. Since DioClient.dio is late final,
/// we use FlutterSecureStorage.setMockInitialValues and then override
/// the dio instance through the constructor flow.
/// Simpler approach: directly test services by injecting a DioClient
/// whose dio property is set through normal construction but with a test
/// interceptor that captures all calls before they hit the network.
DioClient _createTestClient(_MockInterceptor interceptor) {
  // Set mock initial values for FlutterSecureStorage (required for tests)
  FlutterSecureStorage.setMockInitialValues({});
  final client = DioClient(storage: const FlutterSecureStorage());
  // Clear all interceptors and add only our mock interceptor
  client.dio.interceptors.clear();
  client.dio.interceptors.add(interceptor);
  // Override base URL to prevent real network calls
  client.dio.options.baseUrl = 'http://test-server';
  return client;
}

void main() {
  late DioClient fakeClient;
  late _MockInterceptor mockInterceptor;

  setUp(() {
    mockInterceptor = _MockInterceptor();
    fakeClient = _createTestClient(mockInterceptor);
  });

  group('StaffDashboardService', () {
    test('getDashboard calls GET /staff/dashboard', () async {
      mockInterceptor.responseFactory = (_) => {
            'total_students': 10,
            'active_enrollments': 5,
            'pending_documents': 2,
            'upcoming_appointments': 1,
            'active_chat_sessions': 0,
            'enrollment_period': null,
          };

      final service = StaffDashboardService(client: fakeClient);
      final result = await service.getDashboard();

      expect(mockInterceptor.capturedRequests, hasLength(1));
      expect(mockInterceptor.capturedRequests.first.path, '/staff/dashboard');
      expect(mockInterceptor.capturedRequests.first.method, 'GET');
      expect(result.totalStudents, 10);
      expect(result.activeEnrollments, 5);
    });
  });

  group('StaffScheduleService', () {
    late StaffScheduleService service;

    setUp(() {
      service = StaffScheduleService(client: fakeClient);
    });

    test('getAppointments calls GET /appointments', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'apt-1',
              'reason': 'Orientacao',
              'status': 'scheduled',
              'created_at': '2026-05-01T10:00:00Z',
            },
          ];

      final result = await service.getAppointments();

      expect(mockInterceptor.capturedRequests, hasLength(1));
      expect(mockInterceptor.capturedRequests.first.path, '/appointments');
      expect(mockInterceptor.capturedRequests.first.method, 'GET');
      expect(result, hasLength(1));
      expect(result.first.reason, 'Orientacao');
    });

    test('getAppointments passes status query param when provided', () async {
      mockInterceptor.responseFactory = (_) => <dynamic>[];

      await service.getAppointments(status: 'scheduled');

      expect(
        mockInterceptor.capturedRequests.first.queryParameters['status'],
        'scheduled',
      );
    });

    test('getSlots calls GET /scheduling/slots', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'slot-1',
              'date': '2026-05-10',
              'start_time': '09:00',
              'end_time': '09:30',
              'is_available': true,
            },
          ];

      final result = await service.getSlots();

      expect(mockInterceptor.capturedRequests.first.path, '/scheduling/slots');
      expect(result, hasLength(1));
      expect(result.first.isAvailable, true);
    });

    test('getSlots passes date range query params', () async {
      mockInterceptor.responseFactory = (_) => <dynamic>[];

      await service.getSlots(dateFrom: '2026-05-01', dateTo: '2026-05-31');

      final params = mockInterceptor.capturedRequests.first.queryParameters;
      expect(params['date_from'], '2026-05-01');
      expect(params['date_to'], '2026-05-31');
    });

    test('createSlots calls POST /scheduling/slots with correct body',
        () async {
      mockInterceptor.responseFactory = (_) => {};

      await service.createSlots(
        date: '2026-06-01',
        startTime: '10:00',
        endTime: '12:00',
        slotDurationMinutes: 30,
      );

      final req = mockInterceptor.capturedRequests.first;
      expect(req.path, '/scheduling/slots');
      expect(req.method, 'POST');
      expect(req.data['date'], '2026-06-01');
      expect(req.data['start_time'], '10:00');
      expect(req.data['end_time'], '12:00');
      expect(req.data['slot_duration_minutes'], 30);
    });

    test('cancelAppointment calls PUT /appointments/{id}/cancel', () async {
      mockInterceptor.responseFactory = (_) => {};

      await service.cancelAppointment('apt-123');

      final req = mockInterceptor.capturedRequests.first;
      expect(req.path, '/appointments/apt-123/cancel');
      expect(req.method, 'PUT');
    });

    test('confirmAppointment calls PUT /appointments/{id}/confirm', () async {
      mockInterceptor.responseFactory = (_) => {};

      await service.confirmAppointment('apt-456');

      final req = mockInterceptor.capturedRequests.first;
      expect(req.path, '/appointments/apt-456/confirm');
      expect(req.method, 'PUT');
    });
  });

  group('StaffDocumentService', () {
    late StaffDocumentService service;

    setUp(() {
      service = StaffDocumentService(client: fakeClient);
    });

    test('getDocuments calls GET /documents', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'doc-1',
              'type': 'transcript',
              'status': 'requested',
              'requested_at': '2026-05-01T10:00:00Z',
            },
          ];

      final result = await service.getDocuments();

      expect(mockInterceptor.capturedRequests.first.path, '/documents');
      expect(mockInterceptor.capturedRequests.first.method, 'GET');
      expect(result, hasLength(1));
      expect(result.first.type, 'transcript');
    });

    test('getDocuments passes status filter', () async {
      mockInterceptor.responseFactory = (_) => <dynamic>[];

      await service.getDocuments(status: 'ready');

      expect(
        mockInterceptor.capturedRequests.first.queryParameters['status'],
        'ready',
      );
    });

    test('updateDocumentStatus calls PUT /documents/{id}/status', () async {
      mockInterceptor.responseFactory = (_) => {};

      await service.updateDocumentStatus('doc-abc',
          status: 'ready', fileUrl: 'http://file.url/doc.pdf');

      final req = mockInterceptor.capturedRequests.first;
      expect(req.path, '/documents/doc-abc/status');
      expect(req.method, 'PUT');
      expect(req.data['status'], 'ready');
      expect(req.data['file_url'], 'http://file.url/doc.pdf');
    });

    test('createDocument calls POST /documents with correct body', () async {
      mockInterceptor.responseFactory = (_) => {
            'id': 'new-doc',
            'type': 'certificate',
            'status': 'ready',
            'file_url': 'http://file.url/cert.pdf',
            'requested_at': '2026-05-07T10:00:00Z',
          };

      final result = await service.createDocument(
        studentId: 'student-1',
        type: 'certificate',
        fileUrl: 'http://file.url/cert.pdf',
      );

      final req = mockInterceptor.capturedRequests.first;
      expect(req.path, '/documents');
      expect(req.method, 'POST');
      expect(req.data['student_id'], 'student-1');
      expect(req.data['type'], 'certificate');
      expect(req.data['status'], 'ready');
      expect(result.id, 'new-doc');
    });

    test('searchStudents calls GET /students with search and per_page',
        () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'st-1',
              'name': 'Ana',
              'email': 'ana@test.edu',
              'status': 'active',
            },
          ];

      final result = await service.searchStudents('Ana');

      final req = mockInterceptor.capturedRequests.first;
      expect(req.path, '/students');
      expect(req.queryParameters['search'], 'Ana');
      expect(req.queryParameters['per_page'], 10);
      expect(result, hasLength(1));
      expect(result.first.name, 'Ana');
    });
  });

  group('StaffChatService', () {
    late StaffChatService service;

    setUp(() {
      service = StaffChatService(client: fakeClient);
    });

    test('getSessions calls GET /chat-sessions', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'sess-1',
              'status': 'active',
              'started_at': '2026-05-01T10:00:00Z',
            },
          ];

      final result = await service.getSessions();

      expect(mockInterceptor.capturedRequests.first.path, '/chat-sessions');
      expect(result, hasLength(1));
      expect(result.first.isActive, true);
    });

    test('getSessions passes status filter', () async {
      mockInterceptor.responseFactory = (_) => <dynamic>[];

      await service.getSessions(status: 'closed');

      expect(
        mockInterceptor.capturedRequests.first.queryParameters['status'],
        'closed',
      );
    });

    test('getMessages calls GET /chat-sessions/{id}/messages', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'msg-1',
              'role': 'user',
              'content': 'Hello',
              'created_at': '2026-05-01T10:00:00Z',
            },
          ];

      final result = await service.getMessages('sess-1');

      expect(mockInterceptor.capturedRequests.first.path,
          '/chat-sessions/sess-1/messages');
      expect(result, hasLength(1));
      expect(result.first.content, 'Hello');
      expect(result.first.isUser, true);
    });

    test('getActionLogs calls GET /chat-sessions/{id}/action-logs', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 'log-1',
              'tool_name': 'get_grades',
              'input_params': {'semester': 3},
              'status': 'success',
              'created_at': '2026-05-01T10:00:00Z',
            },
          ];

      final result = await service.getActionLogs('sess-1');

      expect(mockInterceptor.capturedRequests.first.path,
          '/chat-sessions/sess-1/action-logs');
      expect(result, hasLength(1));
      expect(result.first.toolName, 'get_grades');
      expect(result.first.isError, false);
    });

    test('getStatistics computes from sessions', () async {
      mockInterceptor.responseFactory = (_) => [
            {
              'id': 's1',
              'status': 'active',
              'started_at': '2026-05-01T10:00:00Z',
            },
            {
              'id': 's2',
              'status': 'closed',
              'started_at': '2026-04-28T10:00:00Z',
            },
            {
              'id': 's3',
              'status': 'active',
              'started_at': '2026-05-02T10:00:00Z',
            },
          ];

      final result = await service.getStatistics();

      expect(result['total_sessions'], 3);
      expect(result['active_sessions'], 2);
      expect(result['closed_sessions'], 1);
    });
  });
}
