import '../../../core/network/dio_client.dart';
import '../../../core/models/auth_tokens.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final DioClient _client;

  AuthService({required DioClient client}) : _client = client;

  /// POST /auth/request-code
  /// Returns message and code expiry time
  Future<RequestCodeResponse> requestCode({
    required String email,
    String channel = 'email',
  }) async {
    final response = await _client.dio.post(
      '/auth/request-code',
      data: {'email': email, 'channel': channel},
    );
    return RequestCodeResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/verify-code
  /// Returns JWT token + user data
  Future<AuthResponse> verifyCode({
    required String email,
    required String code,
    String platform = 'app',
  }) async {
    final response = await _client.dio.post(
      '/auth/verify-code',
      data: {'email': email, 'code': code, 'platform': platform},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /auth/me
  /// Returns current user profile
  Future<UserModel> getMe() async {
    final response = await _client.dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/logout
  /// Invalidates current session
  Future<void> logout() async {
    await _client.dio.post('/auth/logout');
  }
}
