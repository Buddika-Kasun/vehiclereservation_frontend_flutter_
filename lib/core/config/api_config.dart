// config/api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static bool _initialized = false;
  static Map<String, String> _webEnv = {}; // Store web config

  static Future<void> init() async {
    if (!_initialized) {
      if (kIsWeb) {
        // if (!ApiConfig.isProduction) {
        //   await dotenv.load(fileName: "assets/.env"); // Dev
        // }
        // else{
        //   // For web (Railway), load from hardcoded config
        //   _loadWebConfig();                         // Prod
        // }
        _loadWebConfig();                         // Prod
        //await dotenv.load(fileName: "assets/.env"); // Dev
      } else {
        // For mobile/desktop, load from .env file
        await dotenv.load(fileName: "assets/.env");
      }
      _initialized = true;
    }
  }

  // Load configuration for web platform
  static void _loadWebConfig() {
    try {
      // Use your Railway URL here - USE WSS:// FOR WEBSOCKET
      _webEnv = {
        'API_URL': 'https://pcw-ride-server.up.railway.app',
        'WS_URL':
            'wss://pcw-ride-server.up.railway.app', // Fixed: Use wss:// for WebSocket
      };
    } catch (e) {
      // Fallback values
      _webEnv = {
        'API_URL': 'https://pcw-ride-server.up.railway.app',
        'WS_URL': 'wss://pcw-ride-server.up.railway.app', // Fixed
      };
    }
  }

  // Helper method to get values from the right source
  static String _getEnv(String key, String defaultValue) {
    if (kIsWeb && _webEnv.containsKey(key)) {
      return _webEnv[key]!;
    }
    return dotenv.env[key] ?? defaultValue;
  }

  // API Base URL
  static String get baseUrl {
    if (!_initialized) {
      throw Exception(
        'ApiConfig not initialized. Call ApiConfig.init() first.',
      );
    }
    final url = _getEnv('API_URL', 'http://localhost:3000');
    return url.endsWith('/api/v1') ? url : '$url/api/v1';
  }

  // WebSocket Base URL
  static String get wsBaseUrl {
    if (!_initialized) {
      throw Exception(
        'ApiConfig not initialized. Call ApiConfig.init() first.',
      );
    }

    final wsUrl = _getEnv('WS_URL', 'ws://localhost:3000');
    return wsUrl; // Now returns wss:// for web
  }

  // WebSocket namespace/path
  static String get wsNamespace => '/notifications';
  static String get wsPath => '/socket.io/';

  // Complete WebSocket URL
  static String get wsUrl {
    if (!_initialized) {
      throw Exception(
        'ApiConfig not initialized. Call ApiConfig.init() first.',
      );
    }

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
    final apiUrl = _getEnv('API_URL', '');
    return apiUrl.startsWith('https://');
  }

  // Get API URL without /api/v1 suffix
  static String get apiBaseUrlWithoutSuffix {
    if (!_initialized) {
      throw Exception(
        'ApiConfig not initialized. Call ApiConfig.init() first.',
      );
    }

    final url = _getEnv('API_URL', 'http://localhost:3000');
    return url.endsWith('/api/v1')
        ? url.substring(0, url.length - 7) // Remove '/api/v1'
        : url;
  }

  // Optional: Debug method
  static void printCurrentConfig() {
    print('=== Current Config ===');
    print('Platform: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');
    print('API_URL: ${_getEnv('API_URL', 'not set')}');
    print('WS_URL: ${_getEnv('WS_URL', 'not set')}');
    print('Base URL: $baseUrl');
    print('WS Base URL: $wsBaseUrl');
    print('WS URL: $wsUrl');
    print('Is Production: $isProduction');
    print('API without suffix: $apiBaseUrlWithoutSuffix');
    print('=====================');
  }
}
