import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DesafioFCG3App()));
}

class DesafioFCG3App extends ConsumerWidget {
  const DesafioFCG3App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Desafio FCG3',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
