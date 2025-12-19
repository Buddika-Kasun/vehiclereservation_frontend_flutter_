// lib/data/services/ws/handlers/trip_handler.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../websocket_manager.dart';

class TripHandler {
  final WebSocketManager _wsManager = WebSocketManager();
  Timer? _debounceTimer;

  // Callback for trip updates
  Function(Map<String, dynamic>)? onTripUpdate;

  // Initialize handler with Socket.IO
  Future<void> initialize({
    required String token,
    required String userId,
  }) async {
    _wsManager.initialize(token: token, userId: userId);

    // Connect to trips namespace
    await _wsManager.connectToNamespace('trips');

    // Listen for trip events
    _wsManager.addMessageListener('trips', _handleTripMessage);

    if (kDebugMode) {
      print('🚗 TripHandler initialized for user: $userId');
    }
  }

  void _handleTripMessage(Map<String, dynamic> message) {
    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 Trip event: $event');
    }

    // Handle trip refresh events
    if (event == 'refresh') {
      _handleTripRefresh(data);
    }
  }

  void _handleTripRefresh(Map<String, dynamic> data) {
    final scope = data['scope']?.toString() ?? '';

    // Debounce to prevent multiple refreshes
    _debounceRefresh(() {
      if (onTripUpdate != null) {
        onTripUpdate!({'type': 'refresh', 'scope': scope});
      }
    });
  }

  void _debounceRefresh(Function callback) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      callback();
    });
  }

  // Cleanup
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _wsManager.disconnectFromNamespace('trips');
  }
}
