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
import 'package:go_router/go_router.dart';

void main() {
  group('GoRouter redirect guards', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    testWidgets('AuthUnauthenticated state — any path redirects to /login',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _NoOpAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Force unauthenticated state
      await container.read(authProvider.notifier).checkAuthStatus();
      expect(container.read(authProvider), isA<AuthUnauthenticated>());

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should be on login
      expect(router.state!.matchedLocation, RoutePaths.login);

      // Try navigating to /client
      router.go(RoutePaths.clientHome);
      await tester.pumpAndSettle();
      expect(router.state!.matchedLocation, RoutePaths.login);
    });

    testWidgets(
        'AuthAuthenticated (student) accessing /staff/* redirected to /client',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
      });
      const storage = FlutterSecureStorage();
      final service = _MockStudentAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Set up authenticated student state
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

      // Navigate to staff route
      router.go(RoutePaths.staffDashboard);
      await tester.pumpAndSettle();
      expect(router.state!.matchedLocation, RoutePaths.clientHome);
    });

    testWidgets(
        'AuthAuthenticated (staff) accessing /client/* redirected to /staff',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
      });
      const storage = FlutterSecureStorage();
      final service = _MockStaffAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Set up authenticated staff state
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

      // Navigate to client route
      router.go(RoutePaths.clientHome);
      await tester.pumpAndSettle();
      expect(router.state!.matchedLocation, RoutePaths.staffDashboard);
    });

    testWidgets(
        'AuthAuthenticated (student) on splash/login redirects to /client',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
      });
      const storage = FlutterSecureStorage();
      final service = _MockStudentAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkAuthStatus();

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Initial location is splash, which should redirect to /client
      expect(router.state!.matchedLocation, RoutePaths.clientHome);

      // Try to access login while authenticated
      router.go(RoutePaths.login);
      await tester.pumpAndSettle();
      expect(router.state!.matchedLocation, RoutePaths.clientHome);
    });

    testWidgets(
        'AuthAuthenticated (staff) on splash/login redirects to /staff',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
      });
      const storage = FlutterSecureStorage();
      final service = _MockStaffAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkAuthStatus();

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Initial splash should redirect to /staff
      expect(router.state!.matchedLocation, RoutePaths.staffDashboard);
    });

    testWidgets('AuthInitial/AuthLoading stays on splash before auth resolves',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'some-token',
      });
      const storage = FlutterSecureStorage();
      // Use a service whose getMe never completes
      final completer = Completer<UserModel>();
      final service = _CompleterAuthService(completer);
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);

      // State is AuthInitial (not yet checked)
      expect(container.read(authProvider), isA<AuthInitial>());

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      // Pump once to build the widget tree (splash triggers checkAuthStatus)
      await tester.pump();

      // At this point the auth is either AuthInitial or AuthLoading
      // and the router should be on splash
      final authState = container.read(authProvider);
      expect(
        authState is AuthInitial || authState is AuthLoading,
        isTrue,
        reason: 'Auth state should be Initial or Loading while /auth/me is pending',
      );
      expect(router.state!.matchedLocation, RoutePaths.splash);

      // Complete the completer to avoid dangling futures/timers
      completer.complete(const UserModel(
        id: 'x', name: 'x', email: 'x@x.com', role: 'student',
      ));
      await tester.pumpAndSettle();
      container.dispose();
    });
  });
}

/// Auth service that throws (for testing unauthenticated state via checkAuthStatus).
class _NoOpAuthService extends AuthService {
  _NoOpAuthService()
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<UserModel> getMe() async {
    throw Exception('Not authenticated');
  }
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

/// Auth service that never completes getMe (simulates slow API call).
class _SlowAuthService extends AuthService {
  _SlowAuthService()
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<UserModel> getMe() async {
    // Simulate a long-running request — never completes during the test
    await Future.delayed(const Duration(seconds: 30));
    return const UserModel(
      id: 'student-1',
      name: 'Slow User',
      email: 'slow@universidade.edu',
      role: 'student',
    );
  }
}

/// Auth service that completes getMe only when the completer is resolved.
class _CompleterAuthService extends AuthService {
  final Completer<UserModel> _completer;
  _CompleterAuthService(this._completer)
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<UserModel> getMe() => _completer.future;
}
