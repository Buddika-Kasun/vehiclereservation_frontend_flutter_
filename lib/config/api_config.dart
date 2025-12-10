import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      await dotenv.load(fileName: ".env");
      _initialized = true;
    }
  }

  static String get baseUrl {
    if (!_initialized) {
      throw Exception('ApiConfig not initialized');
    }
    final url = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    return url.endsWith('/api/v1') ? url : '$url/api/v1';
  }
}
