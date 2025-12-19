// lib/data/services/ws/handlers/user_handler.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../websocket_manager.dart';
import '../constants/websocket_constants.dart';

class UserHandler {
  final WebSocketManager _wsManager = WebSocketManager();
  Timer? _debounceTimer;

  // Callback for user updates
  Function(Map<String, dynamic>)? onUserUpdate;

  // Initialize handler
  Future<void> initialize({
    required String token,
    required String userId,
  }) async {
    _wsManager.initialize(token: token, userId: userId);

    // Connect to users namespace
    await _wsManager.connectToNamespace(WebSocketConstants.usersNamespace);

    // Listen for user updates
    _wsManager.addMessageListener(
      WebSocketConstants.usersNamespace,
      _handleUserMessage,
    );

    if (kDebugMode) {
      print('👤 UserHandler initialized for user: $userId');
    }
  }

  void _handleUserMessage(Map<String, dynamic> message) {
    final event = message['action']?.toString() ?? '';
    final data = Map<String, dynamic>.from(message['data'] ?? {});

    if (kDebugMode) {
      print('📨 User event: $event');
    }

    // Handle different user events
    switch (event) {
      case 'user_create':
      case 'user_update':
      case 'user_delete':
      case 'user_status_change':
      case 'user_approve':
      case 'user_reject':
        _handleUserEvent(event, data);
        break;
    }
  }

  void _handleUserEvent(String event, Map<String, dynamic> data) {
    // Debounce to prevent multiple refreshes
    _debounceRefresh(() {
      if (onUserUpdate != null) {
        onUserUpdate!({'event': event, 'data': data});
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
    await _wsManager.disconnectFromNamespace(WebSocketConstants.usersNamespace);
  }
}
