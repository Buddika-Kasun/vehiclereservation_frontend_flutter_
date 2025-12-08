class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  
  // Timeout durations
  static const Duration searchTimeout = Duration(seconds: 10);
  static const Duration routeTimeout = Duration(seconds: 15);
}