import 'dart:async';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/fcm_provider.dart';
import '../../../core/providers/notification_handler_provider.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/router/app_router.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

part 'auth_provider.g.dart';

const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() {
    return const AuthInitial();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  /// Check if user has stored valid token on app startup
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    final storage = ref.read(flutterSecureStorageProvider);
    final token = await storage.read(key: _accessTokenKey);

    if (token == null) {
      state = const AuthUnauthenticated();
      return;
    }

    try {
      final user = await _authService.getMe();
      state = AuthAuthenticated(user: user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired or revoked — clear and go to login
        await storage.delete(key: _accessTokenKey);
        await storage.delete(key: _refreshTokenKey);
        state = const AuthUnauthenticated();
      } else {
        // Network error — stay unauthenticated to be safe
        state = const AuthUnauthenticated();
      }
    }
  }

  /// Request OTP code for email
  Future<String?> requestCode(String email) async {
    try {
      final response = await _authService.requestCode(email: email);
      return response.message;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Verify OTP code and authenticate
  Future<AuthVerifyResult> verifyCode(String email, String code) async {
    state = const AuthLoading();
    try {
      final response = await _authService.verifyCode(email: email, code: code);
      final storage = ref.read(flutterSecureStorageProvider);

      // Store tokens
      await storage.write(key: _accessTokenKey, value: response.accessToken);
      await storage.write(key: _refreshTokenKey, value: response.refreshToken);

      try {
        final user = await _authService.getMe();
        state = AuthAuthenticated(user: user);

        // Register FCM token (immediately after login)
        if (user.isStudent) {
          ref.read(fcmServiceProvider.notifier).registerToken(user.id);
        }

        // D-18: Navigate to pending deep-link from notification tap during expired JWT
        final pendingLink = ref
            .read(notificationHandlerProvider.notifier)
            .consumePendingDeepLink();
        if (pendingLink != null) {
          // Small delay so router redirect completes first
          Future.delayed(const Duration(milliseconds: 300), () {
            ref.read(appRouterProvider).go(pendingLink);
          });
        }

        return AuthVerifyResult.success;
      } catch (_) {
        await storage.delete(key: _accessTokenKey);
        await storage.delete(key: _refreshTokenKey);
        state = const AuthError(message: 'Erro de conexao. Tente novamente.');
        return AuthVerifyResult.networkError;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Invalid code
        final errorData = e.response?.data;
        int? remaining;
        if (errorData is Map<String, dynamic>) {
          try {
            final error = errorData['error'] as Map<String, dynamic>?;
            final details = error?['details'];
            if (details is List && details.isNotEmpty) {
              final firstDetail = details[0];
              if (firstDetail is Map<String, dynamic>) {
                remaining = int.tryParse(
                    firstDetail['message']?.toString() ?? '');
              }
            }
          } catch (_) {
            // Gracefully ignore malformed error responses
          }
        }
        state = AuthError(
          message: 'Codigo invalido',
          attemptsRemaining: remaining,
        );
        return AuthVerifyResult.invalidCode;
      } else if (e.response?.statusCode == 429) {
        // Max attempts reached
        state = const AuthError(
          message: 'Tentativas esgotadas — novo codigo enviado',
        );
        return AuthVerifyResult.maxAttempts;
      } else {
        state = const AuthError(message: 'Erro de conexao. Tente novamente.');
        return AuthVerifyResult.networkError;
      }
    }
  }

  /// Logout — clear tokens and reset state
  Future<void> logout() async {
    // Unregister FCM token before clearing auth state
    final currentState = state;
    if (currentState is AuthAuthenticated && currentState.user.isStudent) {
      await ref
          .read(fcmServiceProvider.notifier)
          .unregisterToken(currentState.user.id);
    }

    try {
      await _authService.logout();
    } catch (_) {
      // Even if logout API fails, clear local state
    }
    final storage = ref.read(flutterSecureStorageProvider);
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    state = const AuthUnauthenticated();
  }

  /// Set a demo user for previewing screens without backend.
  void setDemoUser(UserModel user) {
    state = AuthAuthenticated(user: user);
  }
}

enum AuthVerifyResult {
  success,
  invalidCode,
  maxAttempts,
  networkError,
}
