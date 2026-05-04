import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DesafioFCG3App()));
}

class DesafioFCG3App extends StatelessWidget {
  const DesafioFCG3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desafio FCG3',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
            child: Text('Loading...')), // Placeholder until Plan 03 adds GoRouter
      ),
    );
  }
}
