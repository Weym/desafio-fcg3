import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/client/screens/client_shell.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/client_chat_screen.dart';
import '../../features/client/screens/client_chat_detail_screen.dart';
import '../../features/client/screens/client_documents_screen.dart';
import '../../features/client/screens/client_notifications_screen.dart';
import '../../features/client/screens/client_support_screen.dart';
import '../../features/client/screens/client_resources_screen.dart';
import '../../features/staff/screens/staff_shell.dart';
import '../../features/staff/screens/staff_dashboard_screen.dart';
import '../../features/staff/screens/staff_schedule_screen.dart';
import '../../features/staff/screens/staff_appointment_detail_screen.dart';
import '../../features/staff/screens/staff_ai_screen.dart';
import '../../features/staff/screens/staff_chats_screen.dart';
import '../../features/staff/screens/staff_chat_detail_screen.dart';
import '../../features/staff/screens/staff_documents_screen.dart';
import '../../features/staff/screens/staff_resources_screen.dart';
import '../../features/staff/screens/staff_intervention_screen.dart';
import '../../features/staff/screens/staff_intervention_chat_screen.dart';
import '../../features/staff/screens/staff_cadastro_screen.dart';
import '../../features/client/models/appointment_model.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // Use a ValueNotifier + ref.listen to trigger GoRouter.refreshListenable
  // instead of ref.watch, which would recreate the entire GoRouter on every
  // auth state change (causing GlobalKey reuse crashes and navigation stack loss).
  final authNotifier = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen(authProvider, (_, next) {
    authNotifier.value = next;
  });
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode, // IN-02: only log in debug builds
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.value;
      final currentPath = state.matchedLocation;
      final isOnSplash = currentPath == RoutePaths.splash;
      final isOnLogin = currentPath == RoutePaths.login;

      // While checking auth (splash), don't redirect
      if (authState is AuthInitial || authState is AuthLoading) {
        return isOnSplash ? null : RoutePaths.splash;
      }

      // Unauthenticated → login
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return isOnLogin ? null : RoutePaths.login;
      }

      // Authenticated → role-based routing
      if (authState is AuthAuthenticated) {
        final user = authState.user;

        // Redirect away from splash/login
        if (isOnSplash || isOnLogin) {
          return user.isStudent
              ? RoutePaths.clientHome
              : RoutePaths.staffDashboard;
        }

        // Role guards: student blocked from /staff/*
        if (user.isStudent && currentPath.startsWith('/staff')) {
          return RoutePaths.clientHome;
        }

        // Role guards: staff blocked from /client/*
        if (user.isStaff && currentPath.startsWith('/client')) {
          return RoutePaths.staffDashboard;
        }

        return null; // Allow navigation
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Login
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Client shell with 5 tabs
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.clientHome,
            name: RouteNames.clientHome,
            builder: (context, state) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.clientChat,
            name: RouteNames.clientChat,
            builder: (context, state) => const ClientChatScreen(),
            routes: [
              GoRoute(
                path: ':sessionId',
                name: RouteNames.clientChatDetail,
                builder: (context, state) {
                  final sessionId = state.pathParameters['sessionId']!;
                  return ClientChatDetailScreen(sessionId: sessionId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.clientDocuments,
            name: RouteNames.clientDocuments,
            builder: (context, state) =>
                const ClientDocumentsScreen(),
          ),
          GoRoute(
            path: RoutePaths.clientNotifications,
            name: RouteNames.clientNotifications,
            builder: (context, state) =>
                const ClientNotificationsScreen(),
          ),
          GoRoute(
            path: RoutePaths.clientSupport,
            name: RouteNames.clientSupport,
            builder: (context, state) =>
                const ClientSupportScreen(),
          ),
          GoRoute(
            path: RoutePaths.clientResources,
            name: RouteNames.clientResources,
            builder: (context, state) {
              final tab = int.tryParse(
                      state.uri.queryParameters['tab'] ?? '') ??
                  0;
              return ClientResourcesScreen(initialTabIndex: tab);
            },
          ),
        ],
      ),

      // Staff shell with 4 tabs
      ShellRoute(
        builder: (context, state, child) => StaffShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.staffDashboard,
            name: RouteNames.staffDashboard,
            builder: (context, state) => const StaffDashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.staffSchedule,
            name: RouteNames.staffSchedule,
            builder: (context, state) => const StaffScheduleScreen(),
            routes: [
              GoRoute(
                path: ':appointmentId',
                name: RouteNames.staffAppointmentDetail,
                builder: (context, state) {
                  final appointment = state.extra as AppointmentModel;
                  return StaffAppointmentDetailScreen(
                      appointment: appointment);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.staffAI,
            name: RouteNames.staffAI,
            builder: (context, state) => const StaffAiScreen(),
            routes: [
              GoRoute(
                path: ':sessionId',
                name: RouteNames.staffChatDetail,
                builder: (context, state) {
                  final sessionId = state.pathParameters['sessionId']!;
                  return StaffChatDetailScreen(sessionId: sessionId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.staffChats,
            name: RouteNames.staffChats,
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return StaffChatsScreen(initialFilter: filter);
            },
            routes: [
              GoRoute(
                path: ':sessionId',
                name: 'staff-chats-detail',
                builder: (context, state) {
                  final sessionId = state.pathParameters['sessionId']!;
                  return StaffChatDetailScreen(sessionId: sessionId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.staffCadastro,
            name: RouteNames.staffCadastro,
            builder: (context, state) => const StaffCadastroScreen(),
          ),
          GoRoute(
            path: RoutePaths.staffDocuments,
            name: RouteNames.staffDocuments,
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return StaffDocumentsScreen(initialFilter: filter);
            },
          ),
          GoRoute(
            path: RoutePaths.staffResources,
            name: RouteNames.staffResources,
            builder: (context, state) => const StaffResourcesScreen(),
          ),
          GoRoute(
            path: RoutePaths.staffIntervention,
            name: RouteNames.staffIntervention,
            builder: (context, state) => const StaffInterventionScreen(),
            routes: [
              GoRoute(
                path: ':sessionId',
                name: RouteNames.staffInterventionChat,
                builder: (context, state) {
                  final sessionId = state.pathParameters['sessionId']!;
                  return StaffInterventionChatScreen(sessionId: sessionId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
