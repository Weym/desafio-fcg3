class RouteNames {
  // Auth
  static const String splash = 'splash';
  static const String login = 'login';

  // Client tabs
  static const String clientHome = 'client-home';
  static const String clientChat = 'client-chat';
  static const String clientDocuments = 'client-documents';
  static const String clientNotifications = 'client-notifications';
  static const String clientSupport = 'client-support';

  // Client detail
  static const String clientChatDetail = 'client-chat-detail';
  static const String clientResources = 'client-resources';

  // Staff tabs
  static const String staffDashboard = 'staff-dashboard';
  static const String staffSchedule = 'staff-schedule';
  static const String staffAI = 'staff-ai';
  static const String staffDocuments = 'staff-documents';

  // Staff tabs (continued)
  static const String staffResources = 'staff-resources';

  // Staff detail
  static const String staffAppointmentDetail = 'staff-appointment-detail';
  static const String staffChatDetail = 'staff-chat-detail';
}

class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';

  // Client
  static const String clientHome = '/client';
  static const String clientChat = '/client/chat';
  static const String clientChatDetail = '/client/chat/:sessionId';
  static const String clientDocuments = '/client/documents';
  static const String clientNotifications = '/client/notifications';
  static const String clientSupport = '/client/support';
  static const String clientResources = '/client/resources';

  // Staff
  static const String staffDashboard = '/staff';
  static const String staffSchedule = '/staff/schedule';
  static const String staffAI = '/staff/ai';
  static const String staffDocuments = '/staff/documents';

  // Staff tabs (continued)
  static const String staffResources = '/staff/resources';

  // Staff detail
  static const String staffAppointmentDetail = '/staff/schedule/:appointmentId';
  static const String staffChatDetail = '/staff/ai/:sessionId';
}
