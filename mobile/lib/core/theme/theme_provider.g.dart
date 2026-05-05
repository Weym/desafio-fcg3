// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPreferencesHash() => r'8de76f746bd70547e8decb177e3e8072afbe44c3';

/// Provides a [SharedPreferences] instance.
///
/// Copied from [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = Provider<SharedPreferences>.internal(
  sharedPreferences,
  name: r'sharedPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sharedPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = ProviderRef<SharedPreferences>;
String _$themeModeNotifierHash() => r'a99ead3e5d775f716c063a7b2d20c8a596e9cf3e';

/// Manages the app theme mode (light, dark, system) with persistence.
///
/// Default is [ThemeMode.system] per D-18: follows OS preference unless
/// manually overridden by the user.
///
/// Copied from [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
      ThemeModeNotifier.new,
      name: r'themeModeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeModeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeModeNotifier = Notifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
