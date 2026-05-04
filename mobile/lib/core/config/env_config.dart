/// Environment configuration for the app.
///
/// Uses `String.fromEnvironment` for compile-time environment switching
/// via `--dart-define=API_BASE_URL=https://...`.
/// No code generation required — works immediately in dev.
class AppConfig {
  static const String devApiBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String stagingApiBaseUrl = 'https://staging-api.example.com/api/v1';
  static const String prodApiBaseUrl = 'https://api.example.com/api/v1';
  static const int requestTimeoutMs = 30000;
  static const int connectTimeoutMs = 15000;

  static String get apiBaseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: devApiBaseUrl,
  );
}
