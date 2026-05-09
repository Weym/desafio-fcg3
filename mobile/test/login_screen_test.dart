import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/auth_tokens.dart';
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
  group('LoginScreen widget', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    testWidgets('renders email step initially with email field and Enviar código button',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Force unauthenticated to land on login
      await container.read(authProvider.notifier).checkAuthStatus();

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

      // Email field should be present
      expect(find.byType(TextFormField), findsOneWidget);

      // "Enviar código" button should be present
      expect(find.text('Enviar código'), findsOneWidget);

      // "Entrar" heading should be visible
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('email validation shows "Email obrigatório" when empty',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin();
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

      // Tap the submit button without entering email
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Email obrigatório'), findsOneWidget);
    });

    testWidgets('email validation shows "Email inválido" when missing @',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin();
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

      // Enter invalid email without @
      await tester.enterText(find.byType(TextFormField), 'invalidemail');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('after requestCode success transitions to OTP step with Verificar button',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin(requestCodeSuccess: true);
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

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'aluno@universidade.edu');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      // Should transition to OTP step
      expect(find.text('Verificar Código'), findsOneWidget);
      // The AnimatedSwitcher should have switched
      expect(find.text('Enviar código'), findsNothing);
    });

    testWidgets('OTP step shows countdown text "Reenviar código (N s)"',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin(requestCodeSuccess: true);
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

      // Enter valid email and submit
      await tester.enterText(find.byType(TextFormField), 'aluno@universidade.edu');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      // Should show countdown text for resend
      // The countdown starts at 60 and immediately decrements to 59 after 1 sec
      expect(find.textContaining('Reenviar código'), findsOneWidget);
      expect(find.textContaining(' s)'), findsOneWidget);
    });

    testWidgets('back button in OTP step returns to email step',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin(requestCodeSuccess: true);
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

      // Enter valid email and submit
      await tester.enterText(find.byType(TextFormField), 'aluno@universidade.edu');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      // Should be on OTP step
      expect(find.text('Verificar Código'), findsOneWidget);

      // Tap back button (Voltar)
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      // Should return to email step
      expect(find.text('Enviar código'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('after 60s countdown, resend button shows "Reenviar código" without countdown',
        (tester) async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthServiceForLogin(requestCodeSuccess: true);
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

      // Enter valid email and submit
      await tester.enterText(find.byType(TextFormField), 'aluno@universidade.edu');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      // Fast-forward 60 seconds
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();

      // After 60 seconds, should show a clickable "Reenviar código" TextButton
      // The countdown text should be gone, and "Reenviar código" should be a button
      final reenviarFinder = find.widgetWithText(TextButton, 'Reenviar código');
      expect(reenviarFinder, findsOneWidget);
    });
  });
}

/// Mock AuthService for LoginScreen tests.
class _MockAuthServiceForLogin extends AuthService {
  final bool requestCodeSuccess;

  _MockAuthServiceForLogin({this.requestCodeSuccess = false})
      : super(client: DioClient(storage: const FlutterSecureStorage()));

  @override
  Future<RequestCodeResponse> requestCode({
    required String email,
    String channel = 'email',
  }) async {
    if (requestCodeSuccess) {
      return const RequestCodeResponse(
        message: 'Código enviado com sucesso',
        expiresIn: 300,
      );
    }
    throw Exception('Request code failed');
  }

  @override
  Future<UserModel> getMe() async {
    throw Exception('Not authenticated');
  }

  @override
  Future<AuthResponse> verifyCode({
    required String email,
    required String code,
  }) async {
    return const AuthResponse(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      tokenType: 'bearer',
      expiresIn: 900,
    );
  }

  @override
  Future<void> logout() async {}
}
