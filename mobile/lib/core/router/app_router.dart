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
import '../../features/client/screens/client_support_screen.dart';
import '../../features/staff/screens/staff_shell.dart';
import '../../features/staff/screens/staff_home_screen.dart';
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
                const _PlaceholderScreen(title: 'Notificacoes'),
          ),
          GoRoute(
            path: RoutePaths.clientSupport,
            name: RouteNames.clientSupport,
            builder: (context, state) =>
                const ClientSupportScreen(),
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
            builder: (context, state) => const StaffHomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.staffSchedule,
            name: RouteNames.staffSchedule,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Agenda'),
          ),
          GoRoute(
            path: RoutePaths.staffAI,
            name: RouteNames.staffAI,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'IA'),
          ),
          GoRoute(
            path: RoutePaths.staffDocuments,
            name: RouteNames.staffDocuments,
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Documentos'),
          ),
        ],
      ),
    ],
  );
}

/// Placeholder for screens not yet implemented (Phase 8/9)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
