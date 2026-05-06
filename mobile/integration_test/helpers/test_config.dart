/// Shared configuration for integration tests.
///
/// Tests assume the Docker stack is running:
///   docker compose up
///
/// Backend must have DEV_MASTER_OTP=000000 set in environment.
class TestConfig {
  /// Backend API base URL (Flutter web running against local Docker)
  static const String baseUrl = 'http://localhost:8000/api/v1';

  /// DEV_MASTER_OTP bypass code (must match backend DEV_MASTER_OTP env var)
  static const String devOtpCode = '000000';

  /// Test student email (from seed.py — first active student: Ana Silva)
  static const String studentEmail = 'ana.silva@usp.br';

  /// Test staff email (from seed.py — coordinator: Prof. Roberto Almeida)
  static const String staffEmail = 'roberto@icmc.usp.br';

  /// Timeout for API calls in tests
  static const Duration apiTimeout = Duration(seconds: 10);

  /// Generous settle duration for navigation + API calls
  static const Duration settleTimeout = Duration(seconds: 5);
}
