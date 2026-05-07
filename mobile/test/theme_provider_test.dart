import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a ProviderContainer with a real (mocked) SharedPreferences
/// instance, overriding the unimplemented `sharedPreferencesProvider`.
Future<ProviderContainer> _makeContainer({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier default behavior', () {
    test('defaults to ThemeMode.system when no preference is stored',
        () async {
      final container = await _makeContainer();
      addTearDown(container.dispose);

      final mode = container.read(themeModeNotifierProvider);
      expect(mode, ThemeMode.system);
    });

    test('defaults to ThemeMode.system when stored value is unrecognized',
        () async {
      final container =
          await _makeContainer(initialValues: {'theme_mode': 'nonsense'});
      addTearDown(container.dispose);

      final mode = container.read(themeModeNotifierProvider);
      expect(mode, ThemeMode.system);
    });
  });

  group('ThemeModeNotifier reads from SharedPreferences', () {
    test('reads stored "light" as ThemeMode.light', () async {
      final container =
          await _makeContainer(initialValues: {'theme_mode': 'light'});
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.light);
    });

    test('reads stored "dark" as ThemeMode.dark', () async {
      final container =
          await _makeContainer(initialValues: {'theme_mode': 'dark'});
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
    });

    test('reads stored "system" as ThemeMode.system', () async {
      final container =
          await _makeContainer(initialValues: {'theme_mode': 'system'});
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
    });
  });

  group('ThemeModeNotifier.setThemeMode persists and updates state', () {
    test('setThemeMode(dark) persists "dark" under key "theme_mode"',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Initialize the notifier
      expect(container.read(themeModeNotifierProvider), ThemeMode.system);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      // State was updated
      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
      // Persisted to the same SharedPreferences under the expected key
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('setThemeMode(light) persists "light" under key "theme_mode"',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Read once to trigger build
      container.read(themeModeNotifierProvider);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeNotifierProvider), ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('setThemeMode(system) persists "system" under key "theme_mode"',
        () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Starts as dark
      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(ThemeMode.system);

      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });
  });
}
