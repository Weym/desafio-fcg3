import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Standard app bar actions (theme toggle + logout) used across all screens.
///
/// Keeps the UI consistent and avoids duplicating logic.
class AppBarActions extends ConsumerWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: colors.primary,
          ),
          onPressed: () {
            // Toggle based on actual current brightness, not ThemeMode
            final next = isDark ? ThemeMode.light : ThemeMode.dark;
            ref.read(themeModeNotifierProvider.notifier).setThemeMode(next);
          },
          tooltip: 'Alternar tema',
        ),
        IconButton(
          icon: Icon(Icons.logout, color: colors.error),
          onPressed: () => ref.read(authProvider.notifier).logout(),
          tooltip: 'Sair',
        ),
      ],
    );
  }
}
