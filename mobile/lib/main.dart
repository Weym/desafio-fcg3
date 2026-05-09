import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/notification_handler_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase — graceful failure so app works without push notifications
  try {
    await Firebase.initializeApp();

    // Register background handler after Firebase init (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    developer.log(
      'Firebase initialization failed: $e',
      name: 'main',
      level: 900, // WARNING
    );
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AlphaConnectApp(),
    ),
  );
}

class AlphaConnectApp extends ConsumerStatefulWidget {
  const AlphaConnectApp({super.key});

  @override
  ConsumerState<AlphaConnectApp> createState() => _AlphaConnectAppState();
}

class _AlphaConnectAppState extends ConsumerState<AlphaConnectApp> {
  bool _notificationHandlerInitialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    // Initialize notification handler once after first build with context
    if (!_notificationHandlerInitialized) {
      _notificationHandlerInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref
              .read(notificationHandlerProvider.notifier)
              .initialize(context);
        }
      });
    }

    return MaterialApp.router(
      title: 'Alpha Connect',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}
