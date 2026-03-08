// lib/features/trips/mixins/websocket_trip_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

mixin WebSocketTripMixin<T extends StatefulWidget> on State<T> {
  bool isConnected = false;
  bool isInitializing = false;

  // Abstract methods
  Future<String?> getToken();
  Future<String?> getUserId();
  void onTripUpdate(Map<String, dynamic> update);
  void onRefreshEvent(Map<String, dynamic> data);

  Future<void> initializeWebSocket() async {
    // Implement your WebSocket initialization logic here
  }

  void cleanupWebSocket() {
    // Implement cleanup logic here
  }

  void reconnectWebSocket() {
    // Implement reconnection logic here
  }

  void handleWebSocketMessage(Map<String, dynamic> message) {
    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 WebSocket received event: $event');
    }

    if (event == 'refresh') {
      onRefreshEvent(data);
    }
  }

  void handleTripUpdate(Map<String, dynamic> update) {
    final type = update['type']?.toString() ?? '';
    final scope = update['scope']?.toString() ?? '';

    if (kDebugMode) {
      print('🔄 Trip update received: $type, scope: $scope');
    }

    if (scope == 'TRIPS' ||
        scope == 'ALL' ||
        scope == 'MY_RIDES' ||
        scope == 'ASSIGNED_RIDES') {
      onTripUpdate(update);
    }
  }
}
