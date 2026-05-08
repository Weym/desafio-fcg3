import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Image.asset(
                  'assets/images/alpha_connect_logo.jpeg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Alpha Connect',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
