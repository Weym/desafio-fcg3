import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/auth_tokens.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/network/auth_interceptor.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/providers/dio_provider.dart';
import 'package:frontend/core/providers/storage_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/auth_state.dart';
import 'package:frontend/features/auth/services/auth_service.dart';

void main() {
  group('AuthProvider verify-code flow', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('stores TokenPair before fetching /auth/me user', () async {
      const storage = FlutterSecureStorage();
      final service = _RecordingAuthService(storage: storage);
      final container = ProviderContainer(overrides: [
        flutterSecureStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .verifyCode('ana@example.com', '123456');

      expect(result, AuthVerifyResult.success);
      expect(await storage.read(key: 'access_token'), 'new-access-token');
      expect(await storage.read(key: 'refresh_token'), 'new-refresh-token');
      expect(service.accessTokenSeenByGetMe, 'new-access-token');
      expect(service.refreshTokenSeenByGetMe, 'new-refresh-token');

      final state = container.read(authProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.email, 'ana@example.com');
    });

    test('clears stored tokens when /auth/me fails after OTP verification', () async {
      const storage = FlutterSecureStorage();
      final service = _RecordingAuthService(
        storage: storage,
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

      final result = await container
          .read(authProvider.notifier)
          .verifyCode('ana@example.com', '123456');

      expect(result, isNot(AuthVerifyResult.success));
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(container.read(authProvider), isA<AuthError>());
    });
  });

  group('AuthInterceptor refresh flow', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'expired-access-token',
        'refresh_token': 'old-refresh-token',
      });
    });

    test('retries with access_token returned by backend TokenPair', () async {
      final refreshDio = Dio();
      final adapter = _QueuedAdapter([
        ResponseBody.fromString(
          '{"access_token":"refreshed-access-token","refresh_token":"rotated-refresh-token","token_type":"bearer","expires_in":900}',
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        ),
        ResponseBody.fromString('{"ok":true}', 200),
      ]);
      refreshDio.httpClientAdapter = adapter;
      const storage = FlutterSecureStorage();

      final dio = Dio()..interceptors.add(AuthInterceptor(
        storage: storage,
        refreshDio: refreshDio,
      ));
      dio.httpClientAdapter = _QueuedAdapter([
        ResponseBody.fromString('unauthorized', 401),
      ]);

      final response = await dio.get('https://example.test/protected');

      expect(response.statusCode, 200);
      expect(adapter.fetches.last.headers['Authorization'],
          'Bearer refreshed-access-token');
      expect(await storage.read(key: 'access_token'), 'refreshed-access-token');
      expect(await storage.read(key: 'refresh_token'), 'rotated-refresh-token');
    });

    test('does not retry refresh payloads that only use obsolete token key', () async {
      final refreshDio = Dio();
      final adapter = _QueuedAdapter([
        ResponseBody.fromString(
          '{"token":"legacy-token","refresh_token":"rotated-refresh-token"}',
          200,
          headers: {Headers.contentTypeHeader: ['application/json']},
        ),
      ]);
      refreshDio.httpClientAdapter = adapter;
      const storage = FlutterSecureStorage();

      final dio = Dio()..interceptors.add(AuthInterceptor(
        storage: storage,
        refreshDio: refreshDio,
      ));
      dio.httpClientAdapter = _QueuedAdapter([
        ResponseBody.fromString('unauthorized', 401),
      ]);

      await expectLater(
        dio.get('https://example.test/protected'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.fetches, hasLength(1));
      expect(await storage.read(key: 'access_token'), 'expired-access-token');
    });
  });
}

class _RecordingAuthService extends AuthService {
  _RecordingAuthService({required this.storage, this.getMeError})
      : super(client: DioClient(storage: storage));

  final FlutterSecureStorage storage;
  final DioException? getMeError;
  String? accessTokenSeenByGetMe;
  String? refreshTokenSeenByGetMe;

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
    accessTokenSeenByGetMe = await storage.read(key: 'access_token');
    refreshTokenSeenByGetMe = await storage.read(key: 'refresh_token');
    final error = getMeError;
    if (error != null) {
      throw error;
    }
    return const UserModel(
      id: 'student-1',
      name: 'Ana',
      email: 'ana@example.com',
      role: 'student',
    );
  }
}

class _QueuedAdapter implements HttpClientAdapter {
  _QueuedAdapter(this.responses);

  final List<ResponseBody> responses;
  final List<RequestOptions> fetches = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetches.add(options);
    if (responses.isEmpty) {
      return ResponseBody.fromString('unexpected request', 500);
    }
    return responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}
