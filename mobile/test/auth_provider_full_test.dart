import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/auth_tokens.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/providers/dio_provider.dart';
import 'package:frontend/core/providers/storage_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/auth_state.dart';
import 'package:frontend/features/auth/services/auth_service.dart';

void main() {
  group('AuthProvider.requestCode', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('returns message string on success', () async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthService(
        requestCodeResponse: const RequestCodeResponse(
          message: 'Codigo enviado com sucesso',
          expiresIn: 300,
        ),
      );
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .requestCode('aluno@universidade.edu');

      expect(result, 'Codigo enviado com sucesso');
    });

    test('returns null on DioException error', () async {
      const storage = FlutterSecureStorage();
      final service = _MockAuthService(
        requestCodeError: DioException(
          requestOptions: RequestOptions(path: '/auth/request-code'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/request-code'),
            statusCode: 400,
            data: {
              'error': {'code': 'VALIDATION_ERROR', 'message': 'Invalid email'}
            },
          ),
        ),
      );
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .requestCode('invalid-email');

      expect(result, isNull);
    });
  });

  group('AuthProvider.checkAuthStatus', () {
    test('with no stored token transitions to AuthUnauthenticated', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final service = _MockAuthService();
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Initially AuthInitial
      expect(container.read(authProvider), isA<AuthInitial>());

      await container.read(authProvider.notifier).checkAuthStatus();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('with valid stored token and successful /auth/me transitions to AuthAuthenticated',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'valid-token',
        'refresh_token': 'valid-refresh',
      });
      const storage = FlutterSecureStorage();
      final service = _MockAuthService(
        getMeUser: const UserModel(
          id: 'student-1',
          name: 'João',
          email: 'joao@universidade.edu',
          role: 'student',
        ),
      );
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkAuthStatus();

      final state = container.read(authProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.name, 'João');
      expect(state.user.role, 'student');
    });

    test('with expired token (401 from /auth/me) clears tokens and transitions to AuthUnauthenticated',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'expired-token',
        'refresh_token': 'old-refresh',
      });
      const storage = FlutterSecureStorage();
      final service = _MockAuthService(
        getMeError: DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 401,
          ),
        ),
      );
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkAuthStatus();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      // Tokens should be cleared
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
    });
  });

  group('AuthProvider.logout', () {
    test('calls API, clears tokens from storage, sets AuthUnauthenticated',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'active-token',
        'refresh_token': 'active-refresh',
      });
      const storage = FlutterSecureStorage();
      final service = _MockAuthService(
        getMeUser: const UserModel(
          id: 'student-1',
          name: 'João',
          email: 'joao@universidade.edu',
          role: 'student',
        ),
      );
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // First authenticate
      await container.read(authProvider.notifier).checkAuthStatus();
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      // Now logout
      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(service.logoutCalled, isTrue);
    });

    test('clears tokens even when logout API fails', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'active-token',
        'refresh_token': 'active-refresh',
      });
      const storage = FlutterSecureStorage();
      final service = _MockAuthService(
        getMeUser: const UserModel(
          id: 'student-1',
          name: 'João',
          email: 'joao@universidade.edu',
          role: 'student',
        ),
        logoutError: DioException(
          requestOptions: RequestOptions(path: '/auth/logout'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // First authenticate
      await container.read(authProvider.notifier).checkAuthStatus();
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      // Logout with API failure
      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
    });
  });
}

/// Mock AuthService that allows configuring responses for each method.
class _MockAuthService extends AuthService {
  _MockAuthService({
    this.requestCodeResponse,
    this.requestCodeError,
    this.getMeUser,
    this.getMeError,
    this.logoutError,
  }) : super(client: DioClient(storage: const FlutterSecureStorage()));

  final RequestCodeResponse? requestCodeResponse;
  final DioException? requestCodeError;
  final UserModel? getMeUser;
  final DioException? getMeError;
  final DioException? logoutError;
  bool logoutCalled = false;

  @override
  Future<RequestCodeResponse> requestCode({
    required String email,
    String channel = 'email',
  }) async {
    if (requestCodeError != null) throw requestCodeError!;
    return requestCodeResponse ??
        const RequestCodeResponse(message: 'OK', expiresIn: 300);
  }

  @override
  Future<AuthResponse> verifyCode({
    required String email,
    required String code,
  }) async {
    return const AuthResponse(
      accessToken: 'new-access-token',
      refreshToken: 'new-refresh-token',
      tokenType: 'bearer',
      expiresIn: 900,
    );
  }

  @override
  Future<UserModel> getMe() async {
    if (getMeError != null) throw getMeError!;
    return getMeUser ??
        const UserModel(
          id: 'student-1',
          name: 'Default User',
          email: 'user@example.com',
          role: 'student',
        );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (logoutError != null) throw logoutError!;
  }
}
