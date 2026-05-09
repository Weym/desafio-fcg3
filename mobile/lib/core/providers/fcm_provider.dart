import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_state.dart';
import 'dio_provider.dart';

part 'fcm_provider.g.dart';

@Riverpod(keepAlive: true)
class FcmService extends _$FcmService {
  @override
  void build() {
    // Listen for token refresh (auto re-registration)
    FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Request notification permission.
  /// Returns true if permission granted or provisional.
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Register FCM token with backend (immediately after login).
  /// Only registers if notification permission was granted.
  Future<void> registerToken(String studentId) async {
    try {
      final granted = await requestPermission();
      if (!granted) return; // No token if permission denied

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.put(
        '/students/$studentId/fcm-token',
        data: {'token': token},
      );
    } catch (e) {
      // Fire-and-forget — don't crash auth flow if FCM registration fails
      developer.log(
        'FCM token registration failed: $e',
        name: 'FcmService',
      );
    }
  }

  /// Unregister FCM token from backend (on logout).
  Future<void> unregisterToken(String studentId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.delete(
        '/students/$studentId/fcm-token',
        data: {'token': token},
      );
    } catch (e) {
      // Best effort — don't block logout
      developer.log(
        'FCM token unregistration failed: $e',
        name: 'FcmService',
      );
    }
  }

  /// Handle automatic token refresh — re-register with backend.
  void _onTokenRefresh(String newToken) async {
    // Get current auth state to find student ID
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    if (!authState.user.isStudent) return;

    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.put(
        '/students/${authState.user.id}/fcm-token',
        data: {'token': newToken},
      );
    } catch (e) {
      // Best effort — token will be updated on next login
      developer.log(
        'FCM token refresh registration failed: $e',
        name: 'FcmService',
      );
    }
  }
}
