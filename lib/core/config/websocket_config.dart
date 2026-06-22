// config/websocket_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebSocketConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      // Initialize ApiConfig first
        await ApiConfig.init();
      _initialized = true;
    }
  }

  // Socket.IO base URL (without namespace)
  static String get socketIoUrl {
    try {
      if (kIsWeb) {
        // For web, always use the full URL with correct protocol
        // if (!ApiConfig.isProduction) {
        //   return 'http://localhost:3000'; // Dev
        // }
        // return 'https://pcw-ride-server.up.railway.app'; // Prod
        return 'http://localhost:3000'; // Dev
      }

      // For mobile, use from config
      final baseUrl = ApiConfig.wsBaseUrl;

      // Clean up URL
      String cleanUrl = baseUrl;
      if (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }

      print('📡 WebSocket Base URL: $cleanUrl');
      return cleanUrl;
    } catch (e) {
      print('⚠️ WebSocketConfig error: $e');
      // Fallback
      if (kIsWeb) {
        return 'https://pcw-ride-server.up.railway.app';
      }
      return 'http://localhost:3000';
    }
  }

  // Socket.IO connection options - SIMPLIFIED
  static Map<String, dynamic> get connectionOptions {
    final options = {
      'transports': [
        'websocket',
        'polling',
      ], 
      'path': '/socket.io',
      'timeout': 20000,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'autoConnect': false, // Don't auto-connect, we'll control it
      'forceNew': true,
    };

    // For web, add specific options
    if (kIsWeb) {
      options['withCredentials'] = false;
      options['transports'] = ['polling', 'websocket']; // Polling first for web
    }

    return options;
  }

  // Check if connection should be secure
  static bool get isSecure {
    if (kIsWeb) return true;
    final wsUrl = ApiConfig.wsBaseUrl;
    return wsUrl.startsWith('wss://') || wsUrl.startsWith('https://');
  }

  // Debug mode
  static bool get debugMode => true;

  static bool get isProduction {
    if (kIsWeb) return true;
    final wsUrl = ApiConfig.wsBaseUrl;
    return wsUrl.startsWith('wss://') || wsUrl.startsWith('https://');
  }
}
