// config/api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      await dotenv.load(fileName: "assets/.env");
      _initialized = true;
    }
  }

  // API Base URL
  static String get baseUrl {
    if (!_initialized) {
      throw Exception('ApiConfig not initialized');
    }
    final url = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    return url.endsWith('/api/v1') ? url : '$url/api/v1';
  }

  // WebSocket URL (without namespace)
  /*
  static String get wsBaseUrl {
    if (!_initialized) {
      throw Exception('ApiConfig not initialized');
    }
    final wsUrl = dotenv.env['WS_URL'] ?? 'ws://localhost:3000';

    // Ensure proper WebSocket protocol
    if (wsUrl.startsWith('http://')) {
      return wsUrl.replaceFirst('http://', 'ws://');
    } else if (wsUrl.startsWith('https://')) {
      return wsUrl.replaceFirst('https://', 'wss://');
    }
    return wsUrl;
  }
  */
  static String get wsBaseUrl {
    return dotenv.env['WS_URL']!;
  }

  // WebSocket namespace/path
  static String get wsNamespace => '/notifications';
  static String get wsPath => '/socket.io';

  // Complete WebSocket URL
  static String get wsUrl {
    final base = wsBaseUrl.endsWith('/')
        ? wsBaseUrl.substring(0, wsBaseUrl.length - 1)
        : wsBaseUrl;
    return '$base$wsNamespace';
  }

  // Check if we're in production
  static bool get isProduction {
    if (!_initialized) {
      return false;
    }
    final apiUrl = dotenv.env['API_URL'] ?? '';
    return apiUrl.startsWith('https://');
  }

  // Get API URL without /api/v1 suffix
  static String get apiBaseUrlWithoutSuffix {
    final url = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    return url.endsWith('/api/v1')
        ? url.substring(0, url.length - 7) // Remove '/api/v1'
        : url;
  }
}

