import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/client/providers/appointment_provider.dart';
import '../../features/client/providers/document_provider.dart';
import '../../features/client/providers/notification_provider.dart';
import '../router/app_router.dart';
import 'notification_routes.dart';

part 'notification_handler_provider.g.dart';

/// Top-level background handler (must be top-level function per Firebase docs).
/// Background messages: system displays notification automatically (D-16).
/// No custom handling needed — notification field in payload handles display.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System tray notification is shown automatically by Firebase SDK
  // when the message contains a `notification` field.
  developer.log(
    'Background message received: ${message.messageId}',
    name: 'FCM',
  );
}

@Riverpod(keepAlive: true)
class NotificationHandler extends _$NotificationHandler {
  /// Stores pending deep-link path when app was opened from notification
  /// but JWT was expired (per D-18).
  String? _pendingDeepLink;

  @override
  void build() {
    // Will be initialized explicitly after auth is ready
  }

  /// Call this after Firebase.initializeApp() and widget tree is built.
  /// Requires BuildContext for ScaffoldMessenger access.
  void initialize(BuildContext context) {
    // Foreground messages (D-13, D-14, D-15)
    FirebaseMessaging.onMessage.listen((message) {
      if (!context.mounted) return;
      _handleForegroundMessage(context, message);
    });

    // Notification tap when app is in background (D-17)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });

    // Cold start: app opened from terminated state via notification (D-19)
    _checkInitialMessage();
  }

  /// Handle foreground notification (D-13, D-14, D-15).
  void _handleForegroundMessage(BuildContext context, RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    if (notification == null) return;

    // D-15: Auto-refresh data on current screen regardless
    _triggerDataRefresh(data);

    // D-14: Suppress snackbar if already on target screen
    final router = ref.read(appRouterProvider);
    final currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;
    if (NotificationRouter.isAlreadyOnTarget(currentPath, data)) {
      return; // Suppressed — data already refreshing
    }

    // D-13: Show floating snackbar with tap action
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(notification.body ?? ''),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            final targetPath = NotificationRouter.routeFor(data);
            router.go(targetPath);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle notification tap (background → foreground) (D-17).
  void _handleNotificationTap(RemoteMessage message) {
    // T-22-12: Only use hardcoded RoutePaths — no path from raw payload
    final targetPath = NotificationRouter.routeFor(message.data);
    final router = ref.read(appRouterProvider);
    router.go(targetPath);
  }

  /// Check if app was opened from a notification (cold start) (D-19).
  Future<void> _checkInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Store as pending deep-link — auth redirect will pick it up (D-18)
      _pendingDeepLink = NotificationRouter.routeFor(initialMessage.data);

      // Navigate after router has initialized
      final router = ref.read(appRouterProvider);
      await Future.delayed(const Duration(milliseconds: 500));
      router.go(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }

  /// Called after successful re-authentication to navigate to pending deep-link (D-18).
  /// Returns the pending path or null if no pending link exists.
  String? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  /// Trigger data refresh on relevant providers (D-15).
  void _triggerDataRefresh(Map<String, dynamic> data) {
    final event = data['event'] as String?;
    switch (event) {
      case 'document_ready':
        ref.invalidate(documentsProvider);
        ref.invalidate(derivedNotificationsProvider);
        break;
      case 'enrollment_confirmed':
        // Enrollment data refreshed via derived notifications
        ref.invalidate(derivedNotificationsProvider);
        break;
      case 'appointment_confirmed':
        ref.invalidate(appointmentsProvider);
        ref.invalidate(derivedNotificationsProvider);
        break;
    }
  }
}
