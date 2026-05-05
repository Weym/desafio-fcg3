import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/auth_tokens.dart';
import 'package:frontend/core/models/user_model.dart';

void main() {
  group('AuthResponse TokenPair contract', () {
    test('parses backend TokenPair without user or legacy token fields', () {
      final response = AuthResponse.fromJson(const {
        'access_token': 'access-token-value',
        'refresh_token': 'refresh-token-value',
        'token_type': 'bearer',
        'expires_in': 900,
      });

      expect(response.accessToken, 'access-token-value');
      expect(response.refreshToken, 'refresh-token-value');
      expect(response.tokenType, 'bearer');
      expect(response.expiresIn, 900);
    });

    test('serializes using backend snake_case TokenPair keys', () {
      const response = AuthResponse(
        accessToken: 'access-token-value',
        refreshToken: 'refresh-token-value',
        tokenType: 'bearer',
        expiresIn: 900,
      );

      expect(response.toJson(), const {
        'access_token': 'access-token-value',
        'refresh_token': 'refresh-token-value',
        'token_type': 'bearer',
        'expires_in': 900,
      });
    });
  });

  group('UserModel auth profile contract', () {
    test('parses role from /auth/me role key', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'name': 'Ana',
        'email': 'ana@example.com',
        'role': 'student',
      });

      expect(user.role, 'student');
      expect(user.isStudent, isTrue);
    });

    test('preserves fallback support for legacy type key', () {
      final user = UserModel.fromJson(const {
        'id': '2',
        'name': 'Bea',
        'email': 'bea@example.com',
        'type': 'staff',
      });

      expect(user.role, 'staff');
      expect(user.isStaff, isTrue);
    });
  });
}
