import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
//import 'dart:js' as js; // Add this import

class ApiConfig {
  static bool _initialized = false;
  static Map<String, String> _webEnv = {}; // Add this line

  static Future<void> init() async {
    if (!_initialized) {
      if (kIsWeb) {
        // For web (Railway), load from JavaScript config
        _loadWebConfig(); // Add this
      } else {
        // For mobile/desktop, keep existing .env loading
        await dotenv.load(fileName: "assets/.env");
      }
      _initialized = true;
    }
  }

  // Add this method
  static void _loadWebConfig() {
    try {
      //final config = js.context['config'];
      /*
      if (config != null) {
        _webEnv = {
          'API_URL': config['apiUrl']?.toString() ?? 'https://api.example.com',
          'WS_URL': config['wsUrl']?.toString() ?? 'wss://api.example.com',
        };
      }
      */

      _webEnv = {
        'API_URL': 'https://pcw-ride-server.up.railway.app',
        'WS_URL': 'https://pcw-ride-server.up.railway.app',
      };
    } catch (e) {
      // Fallback values for web
      _webEnv = {
        'API_URL': 'https://api.example.com',
        'WS_URL': 'wss://api.example.com',
      };
    }
  }

  // Helper method to get values
  static String _getEnv(String key, String defaultValue) {
    if (kIsWeb && _webEnv.containsKey(key)) {
      return _webEnv[key]!;
    }
    return dotenv.env[key] ?? defaultValue;
  }

  // API Base URL - Update just the getter
  static String get baseUrl {
    if (!_initialized) {
      throw Exception('ApiConfig not initialized');
    }
    final url = _getEnv(
      'API_URL',
      'http://localhost:3000',
    ); // Changed this line
    return url.endsWith('/api/v1') ? url : '$url/api/v1';
  }

  // WebSocket URL - Update just the getter
  static String get wsBaseUrl {
    // Remove the fallback logic, just get from env
    return _getEnv('WS_URL', 'ws://localhost:3000'); // Changed this line
  }

  // WebSocket namespace/path - NO CHANGE
  static String get wsNamespace => '/notifications';
  static String get wsPath => '/socket.io';

  // Complete WebSocket URL - NO CHANGE
  static String get wsUrl {
    final base = wsBaseUrl.endsWith('/')
        ? wsBaseUrl.substring(0, wsBaseUrl.length - 1)
        : wsBaseUrl;
    return '$base$wsNamespace';
  }

  // Check if we're in production - Update this getter
  static bool get isProduction {
    if (!_initialized) {
      return false;
    }
    final apiUrl = _getEnv('API_URL', ''); // Changed this line
    return apiUrl.startsWith('https://');
  }

  // Get API URL without /api/v1 suffix - Update this getter
  static String get apiBaseUrlWithoutSuffix {
    final url = _getEnv(
      'API_URL',
      'http://localhost:3000',
    ); // Changed this line
    return url.endsWith('/api/v1') ? url.substring(0, url.length - 7) : url;
  }

  // Optional: Add this method for debugging
  static void printCurrentConfig() {
    print('=== Current Config ===');
    print('API_URL: ${_getEnv('API_URL', 'not set')}');
    print('WS_URL: ${_getEnv('WS_URL', 'not set')}');
    print('Base URL: $baseUrl');
    print('WS URL: $wsUrl');
    print('Is Production: $isProduction');
  }
}
