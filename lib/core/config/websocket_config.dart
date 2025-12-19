// config/websocket_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';

class WebSocketConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      await dotenv.load(fileName: ".env");
      _initialized = true;
    }
  }

  static String get socketIoBaseUrl {
    return ApiConfig.wsUrl;
  }

  static Map<String, dynamic> get options {
    return {
      'transports': ['websocket'],
      'path': ApiConfig.wsPath,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'timeout': 20000,
      'autoConnect': false,
    };
  }

  // WebSocket connection configuration
  static Map<String, dynamic> get connectionOptions {
    return {
      'transports': ['polling', 'websocket'], // polling first, then websocket
      'path': ApiConfig.wsPath,
      'timeout': 30000,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'autoConnect': true,
    };
  }

  // Get WebSocket URL for Socket.IO
  /*
  static String get socketIoBaseUrl {
    if (!_initialized) {
      throw Exception('WebSocketConfig not initialized');
    }

    // For Socket.IO, we need the base URL without namespace
    final baseUrl = ApiConfig.wsBaseUrl;

    // Clean up URL
    String cleanUrl = baseUrl;
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    // Ensure proper protocol
    if (isSecure) {
      if (!cleanUrl.startsWith('wss://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'wss://${cleanUrl.replaceAll(RegExp(r'^.*://'), '')}';
      }
    } else {
      if (!cleanUrl.startsWith('ws://') && !cleanUrl.startsWith('http://')) {
        cleanUrl = 'ws://${cleanUrl.replaceAll(RegExp(r'^.*://'), '')}';
      }
    }

    return cleanUrl;
  }
  */

// Get WebSocket URL for Socket.IO
static String get socketIoUrl {
  if (!_initialized) {
    throw Exception('WebSocketConfig not initialized');
  }

  // For Socket.IO, we need the base URL without namespace
  final baseUrl = ApiConfig.wsBaseUrl;

  // Clean up URL
  String cleanUrl = baseUrl;
  if (cleanUrl.endsWith('/')) {
    cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
  }

  // Ensure proper protocol
  if (isSecure) {
    if (!cleanUrl.startsWith('wss://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'wss://${cleanUrl.replaceAll(RegExp(r'^.*://'), '')}';
    }
  } else {
    if (!cleanUrl.startsWith('ws://') && !cleanUrl.startsWith('http://')) {
      cleanUrl = 'ws://${cleanUrl.replaceAll(RegExp(r'^.*://'), '')}';
    }
  }

  return cleanUrl;
}

// Get WebSocket URL for specific namespace
static String getNamespaceUrl(String namespace) {
  if (!_initialized) {
    throw Exception('WebSocketConfig not initialized');
  }

  // Use the base WS URL without the old /notifications namespace
  String baseUrl = ApiConfig.wsBaseUrl;

  // Ensure namespace starts with /
  if (!namespace.startsWith('/')) {
    namespace = '/$namespace';
  }

  // Append namespace to base URL
  if (baseUrl.endsWith('/')) {
    return '${baseUrl.substring(0, baseUrl.length - 1)}$namespace';
  } else {
    return '$baseUrl$namespace';
  }
}

  // Check if connection should be secure
  static bool get isSecure {
    final wsUrl = dotenv.env['WS_URL'] ?? '';
    return wsUrl.startsWith('wss://') || wsUrl.startsWith('https://');
  }

  // Debug mode for WebSocket
  static bool get debugMode {
    if (!_initialized) return true;
    return dotenv.env['WS_DEBUG']?.toLowerCase() == 'true' || !isProduction;
  }

  static bool get isProduction {
    final wsUrl = dotenv.env['WS_URL'] ?? '';
    return wsUrl.startsWith('wss://');
  }

  // Ping interval in milliseconds
  static int get pingInterval => 25000;

  // Ping timeout in milliseconds
  static int get pingTimeout => 60000;
}

