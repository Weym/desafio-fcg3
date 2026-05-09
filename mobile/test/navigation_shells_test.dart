import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/providers/dio_provider.dart';
import 'package:frontend/core/providers/storage_provider.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/auth_state.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/core/network/dio_client.dart';

void main() {
  group('SplashScreen', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test-token',
      });
    });

    testWidgets('calls checkAuthStatus on initialization and shows CircularProgressIndicator',
        (tester) async {
      const storage = FlutterSecureStorage();
      final completer = Completer<UserModel>();
      final service = _CompleterAuthService(completer);
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      // Splash should be displayed with CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Auth state should be Loading (checkAuthStatus was called)
      final authState = container.read(authProvider);
      expect(authState, isA<AuthLoading>());

      // Cleanup
      completer.complete(const UserModel(
        id: 'x', name: 'x', email: 'x@x.com', role: 'student',
      ));
      await tester.pumpAndSettle();
      container.dispose();
    });
  });

  group('ClientShell', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
      });
    });

    testWidgets('renders navigation with 5 destinations (Início, Chat, Documentos, Notificações, Recursos)',
        (tester) async {
      // Default 800x600 test viewport triggers tablet mode (NavigationRail)
      const storage = FlutterSecureStorage();
      final service = _MockStudentAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Authenticate as student
      await container.read(authProvider.notifier).checkAuthStatus();
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should be on /client and show the client shell with nav items
      expect(router.state!.matchedLocation, RoutePaths.clientHome);

      // NavigationRail renders 5 destinations with labels
      // (some labels may appear twice due to NavigationRail's internal rendering)
      expect(find.text('Início'), findsAtLeastNWidgets(1));
      expect(find.text('Chat'), findsAtLeastNWidgets(1));
      expect(find.text('Documentos'), findsAtLeastNWidgets(1));
      expect(find.text('Notificações'), findsAtLeastNWidgets(1));
      expect(find.text('Recursos'), findsAtLeastNWidgets(1));
    });
  });

  group('StaffShell', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
      });
    });

    testWidgets('renders navigation with 5 destinations (Painel, Agenda, Intervenção, Documentos, Recursos)',
        (tester) async {
      // Default 800x600 test viewport triggers tablet mode (NavigationRail)
      const storage = FlutterSecureStorage();
      final service = _MockStaffAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Authenticate as staff
      await container.read(authProvider.notifier).checkAuthStatus();
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should be on /staff
      expect(router.state!.matchedLocation, RoutePaths.staffDashboard);

      // StaffShell NavigationRail renders 5 destinations with labels
      // (some labels may appear twice due to NavigationRail's internal rendering)
      expect(find.text('Painel'), findsAtLeastNWidgets(1));
      expect(find.text('Agenda'), findsAtLeastNWidgets(1));
      expect(find.text('Intervenção'), findsAtLeastNWidgets(1));
      expect(find.text('Documentos'), findsAtLeastNWidgets(1));
      expect(find.text('Recursos'), findsAtLeastNWidgets(1));
    });
  });
}

/// Auth service whose getMe completes only when the completer resolves.
class _CompleterAuthService extends AuthService {
  final Completer<UserModel> _completer;
  _CompleterAuthService(this._completer)
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<UserModel> getMe() => _completer.future;
}

/// Auth service returning a student user.
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

/// Auth service returning a staff user.
class _MockStaffAuthService extends AuthService {
  _MockStaffAuthService()
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<UserModel> getMe() async {
    return const UserModel(
      id: 'staff-1',
      name: 'Admin User',
      email: 'admin@universidade.edu',
      role: 'staff',
    );
  }
}
