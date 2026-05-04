import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uses QueuedInterceptor to properly serialize async operations.
/// This prevents the void-async pitfall where handler.next fires before
/// await completes, and serializes concurrent refresh attempts.
class AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio; // Separate Dio instance for refresh to avoid interceptor loop

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  AuthInterceptor({
    required FlutterSecureStorage storage,
    required Dio refreshDio,
  })  : _storage = storage,
        _dio = refreshDio;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.extra.containsKey('isRetry')) {
      // Attempt silent refresh
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          // Safe type checking (WR-01 fix)
          final data = response.data;
          if (data is! Map<String, dynamic>) {
            return handler.next(err);
          }
          final newAccessToken = data['token'] as String?;
          final newRefreshToken = data['refresh_token'] as String?;
          if (newAccessToken == null || newRefreshToken == null) {
            return handler.next(err);
          }

          await _storage.write(key: _accessTokenKey, value: newAccessToken);
          await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

          // Retry original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          options.extra['isRetry'] = true;

          final retryResponse = await _dio.fetch(options);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh failed — clear tokens, let error propagate
          await _storage.delete(key: _accessTokenKey);
          await _storage.delete(key: _refreshTokenKey);
        }
      }
    }
    handler.next(err);
  }
}
