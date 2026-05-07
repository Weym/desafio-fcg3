import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/providers/dio_provider.dart';
import 'package:frontend/core/providers/storage_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/auth_state.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/client/models/chat_session_model.dart';
import 'package:frontend/features/client/models/document_model.dart';
import 'package:frontend/features/client/models/appointment_model.dart';
import 'package:frontend/features/client/providers/chat_provider.dart';
import 'package:frontend/features/client/providers/document_provider.dart';
import 'package:frontend/features/client/providers/appointment_provider.dart';
import 'package:frontend/features/client/screens/client_home_screen.dart';

/// Auth service returning a student user for tests.
class _MockStudentAuthService extends AuthService {
  _MockStudentAuthService()
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<UserModel> getMe() async {
    return const UserModel(
      id: 'student-1',
      name: 'João Aluno',
      email: 'joao@universidade.edu',
      role: 'student',
    );
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-token',
    });
  });

  Widget buildTestWidget({
    List<ChatSessionModel> sessions = const [],
    List<DocumentModel> documents = const [],
    List<AppointmentModel> appointments = const [],
  }) {
    const storage = FlutterSecureStorage();
    final service = _MockStudentAuthService();

    return ProviderScope(
      overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
        chatSessionsProvider.overrideWith((ref) async => sessions),
        documentsProvider.overrideWith((ref) async => documents),
        appointmentsProvider.overrideWith((ref) async => appointments),
      ],
      child: const MaterialApp(
        home: _AuthInitializer(child: ClientHomeScreen()),
      ),
    );
  }

  group('ClientHomeScreen dashboard widget', () {
    testWidgets('user sees greeting with their name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('João Aluno'), findsOneWidget);
    });

    testWidgets('user sees summary cards after data loads', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(buildTestWidget(
        sessions: [
          ChatSessionModel(
            id: 'sess-1',
            status: 'active',
            startedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        appointments: [
          AppointmentModel(
            id: 'apt-1',
            reason: 'Reuniao',
            status: 'scheduled',
            slotDate: '2026-05-10',
            slotStartTime: '14:00',
            createdAt: now,
          ),
        ],
        documents: [
          DocumentModel(
            id: 'doc-1',
            type: 'transcript',
            status: 'ready',
            requestedAt: now.subtract(const Duration(days: 3)),
            completedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Should show chat card with last interaction info
      expect(find.textContaining('Chatbot'), findsOneWidget);
      // Should show appointment card
      expect(find.textContaining('Agendamentos'), findsOneWidget);
    });

    testWidgets('user sees quick action buttons for navigation',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Quick actions should be present
      expect(find.textContaining('Solicitar documento'), findsOneWidget);
      expect(find.textContaining('Suporte'), findsOneWidget);
    });

    testWidgets('user sees empty state when no data is available',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        sessions: [],
        documents: [],
        appointments: [],
      ));
      await tester.pumpAndSettle();

      // The screen should render successfully with no data
      expect(find.byType(ClientHomeScreen), findsOneWidget);
      // Empty state for chat card
      expect(find.textContaining('Nenhuma'), findsOneWidget);
    });

    testWidgets('user can pull to refresh the dashboard', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // The RefreshIndicator should be present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}

/// Helper widget that initializes auth state before rendering child.
class _AuthInitializer extends ConsumerStatefulWidget {
  final Widget child;
  const _AuthInitializer({required this.child});

  @override
  ConsumerState<_AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends ConsumerState<_AuthInitializer> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(authProvider.notifier).checkAuthStatus());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
