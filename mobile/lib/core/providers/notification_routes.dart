import '../router/route_names.dart';

/// Maps notification event types to GoRouter paths.
/// Centralized per D-20 for maintainability and testability.
class NotificationRouter {
  /// Returns the route path for a given notification event.
  /// [data] contains event-specific IDs from the notification payload.
  static String routeFor(Map<String, dynamic> data) {
    final event = data['event'] as String?;
    switch (event) {
      case 'document_ready':
        return RoutePaths.clientDocuments;
      case 'enrollment_confirmed':
        return RoutePaths.clientHome;
      case 'appointment_confirmed':
        return RoutePaths.clientSupport;
      default:
        // T-22-11: Unknown events route to safe default (clientHome)
        return RoutePaths.clientHome;
    }
  }

  /// Check if the user is already on the target screen (per D-14).
  /// Used to suppress foreground snackbar when already viewing relevant content.
  static bool isAlreadyOnTarget(String currentPath, Map<String, dynamic> data) {
    final targetPath = routeFor(data);
    return currentPath == targetPath;
  }
}
