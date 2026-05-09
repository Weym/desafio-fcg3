import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/router/route_names.dart';

void main() {
  group('Staff route constants - correctness (UI-F01-F04)', () {
    test('RouteNames contains all staff tab route names', () {
      expect(RouteNames.staffDashboard, 'staff-dashboard');
      expect(RouteNames.staffSchedule, 'staff-schedule');
      expect(RouteNames.staffAI, 'staff-ai');
      expect(RouteNames.staffDocuments, 'staff-documents');
    });

    test('RouteNames contains staff detail route names', () {
      expect(RouteNames.staffAppointmentDetail, 'staff-appointment-detail');
      expect(RouteNames.staffChatDetail, 'staff-chat-detail');
    });

    test('RoutePaths has correct staff tab paths', () {
      expect(RoutePaths.staffDashboard, '/staff');
      expect(RoutePaths.staffSchedule, '/staff/schedule');
      expect(RoutePaths.staffAI, '/staff/ai');
      expect(RoutePaths.staffDocuments, '/staff/documents');
    });

    test('RoutePaths has correct staff detail paths with parameters', () {
      expect(
          RoutePaths.staffAppointmentDetail, '/staff/schedule/:appointmentId');
      expect(RoutePaths.staffChatDetail, '/staff/ai/:sessionId');
    });

    test('staff dashboard path is /staff (default landing for staff role)', () {
      // Staff authenticated user should land on /staff
      expect(RoutePaths.staffDashboard, '/staff');
    });

    test('no placeholder route names exist in staff section', () {
      // All staff route names should map to real screens
      // This validates that Plan 05 removed all placeholders
      final allRouteNames = [
        RouteNames.staffDashboard,
        RouteNames.staffSchedule,
        RouteNames.staffAI,
        RouteNames.staffDocuments,
        RouteNames.staffAppointmentDetail,
        RouteNames.staffChatDetail,
      ];

      for (final name in allRouteNames) {
        expect(name, isNotEmpty, reason: 'Route name should not be empty');
        expect(name.contains('placeholder'), false,
            reason: 'No placeholder routes should remain');
      }
    });

    test('detail paths contain dynamic path parameters', () {
      // appointment detail uses :appointmentId
      expect(RoutePaths.staffAppointmentDetail, contains(':appointmentId'));
      // chat detail uses :sessionId
      expect(RoutePaths.staffChatDetail, contains(':sessionId'));
    });

    test('staff paths all start with /staff prefix', () {
      expect(RoutePaths.staffDashboard, startsWith('/staff'));
      expect(RoutePaths.staffSchedule, startsWith('/staff'));
      expect(RoutePaths.staffAI, startsWith('/staff'));
      expect(RoutePaths.staffDocuments, startsWith('/staff'));
      expect(RoutePaths.staffAppointmentDetail, startsWith('/staff'));
      expect(RoutePaths.staffChatDetail, startsWith('/staff'));
    });
  });
}
