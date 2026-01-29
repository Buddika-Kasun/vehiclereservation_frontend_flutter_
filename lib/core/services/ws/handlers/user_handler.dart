// lib/data/services/ws/handlers/user_handler.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/global_websocket.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';

class UserHandler {
  // Use global instance
  WebSocketManager get _wsManager => GlobalWebSocket.instance;

  Timer? _debounceTimer;

  // Callback for user updates
  Function(Map<String, dynamic>)? onUserUpdate;

  // Callback for specific user events
  Function(String, Map<String, dynamic>)? onUserEvent;

  // Initialize handler
  Future<void> initialize({
    required String token,
    required String userId,
  }) async {
    // Initialize global WebSocket if needed
    GlobalWebSocket.initialize(token: token, userId: userId);

    // Connect to users namespace
    await _wsManager.connectToNamespace('users');

    // Listen for user events
    _wsManager.addMessageListener('users', _handleUserMessage);

    if (kDebugMode) {
      print('👤 UserHandler initialized for user: $userId');
    }
  }

  void _handleUserMessage(Map<String, dynamic> message) {
    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 UserHandler received event: $event');
    }

    // Handle different user events
    switch (event) {
      case 'user_update':
        _handleUserUpdate(data);
        break;
      case 'refresh':
        _handleRefresh(data);
        break;
      case 'connected':
      case 'disconnected':
        // Connection status events
        break;
    }
  }

  void _handleUserUpdate(Map<String, dynamic> data) {
    final action = data['action']?.toString() ?? '';
    final userData = Map<String, dynamic>.from(data['data'] ?? {});

    if (kDebugMode) {
      print('🔄 User update action: $action');
    }

    // Handle different user actions
    switch (action) {
      case 'user_create':
      case 'user_update':
      case 'user_delete':
      case 'user_approve':
      case 'user_reject':
      case 'user_status_change':
        _debounceRefresh(() {
          if (onUserUpdate != null) {
            onUserUpdate!({'action': action, 'data': userData});
          }

          // Also trigger specific event callback
          if (onUserEvent != null) {
            onUserEvent!(action, userData);
          }
        });
        break;
    }
  }

  void _handleRefresh(Map<String, dynamic> data) {
    final scope = data['scope']?.toString() ?? 'ALL';

    if (kDebugMode) {
      print('🔄 User refresh event, scope: $scope');
    }

    // Only refresh if scope is relevant to users
    if (scope == 'USERS' || scope == 'ALL') {
      _debounceRefresh(() {
        if (onUserUpdate != null) {
          onUserUpdate!({'action': 'refresh', 'data': data});
        }
      });
    }
  }

  void _debounceRefresh(Function callback) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      callback();
    });
  }

  // Emit user event
  void emitUserEvent(String action, Map<String, dynamic> data) {
    _wsManager.emit('users', 'user_event', {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Cleanup
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _wsManager.disconnectFromNamespace('users');
  }
}
