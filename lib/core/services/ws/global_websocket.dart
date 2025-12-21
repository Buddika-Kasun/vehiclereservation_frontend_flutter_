// lib/data/services/ws/global_websocket.dart
import 'websocket_manager.dart';

class GlobalWebSocket {
  static final WebSocketManager _instance = WebSocketManager();

  static WebSocketManager get instance => _instance;

  // Prevent multiple initializations
  static bool _isInitialized = false;

  static void initialize({required String token, required String userId}) {
    if (!_isInitialized) {
      _instance.initialize(token: token, userId: userId);
      _isInitialized = true;
    }
  }

  static bool get isInitialized => _isInitialized;
}
