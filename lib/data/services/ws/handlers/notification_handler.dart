// lib/data/services/ws/handlers/notification_handler.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../websocket_manager.dart';

class NotificationHandler {
  final WebSocketManager _wsManager = WebSocketManager();
  Timer? _debounceTimer;
  bool _hasMaxCount = false;

  // Callback for unread count updates
  Function(int)? onUnreadCountUpdate;

  // Callback for new notifications
  Function(Map<String, dynamic>)? onNewNotification;

  // Initialize handler with Socket.IO
  Future<void> initialize({
    required String token,
    required String userId,
  }) async {
    _wsManager.initialize(token: token, userId: userId);

    // Connect to notifications namespace
    await _wsManager.connectToNamespace('notifications');

    // Listen for notification events
    _wsManager.addMessageListener('notifications', _handleNotificationMessage);

    if (kDebugMode) {
      print('🔔 NotificationHandler initialized for user: $userId');
    }
  }

  void _handleNotificationMessage(Map<String, dynamic> message) {
    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 Notification event: $event');
    }

    // Handle different notification events
    switch (event) {
      case 'notification_update':
        _handleNotificationUpdate(data);
        break;
      case 'refresh':
        _handleRefresh(data);
        break;
    }
  }

  void _handleNotificationUpdate(Map<String, dynamic> data) {
    final action = data['action']?.toString() ?? '';
    final notificationData = Map<String, dynamic>.from(data['data'] ?? {});

    if (kDebugMode) {
      print('📨 Notification action: $action');
    }

    // Handle different actions
    switch (action) {
      case 'notification_create':
        _handleNotificationCreate(notificationData);
        break;
      case 'notification_read':
        _handleNotificationRead(notificationData);
        break;
      case 'notification_read_all':
        _handleNotificationReadAll(notificationData);
        break;
      case 'notification_delete':
        _handleNotificationDelete(notificationData);
        break;
    }
  }

  void _handleRefresh(Map<String, dynamic> data) {
    // When refresh event comes, trigger unread count update
    if (onUnreadCountUpdate != null && !_hasMaxCount) {
      _debounceRefresh(() {
        if (onUnreadCountUpdate != null) {
          onUnreadCountUpdate!(-1); // -1 means "refresh via API"
        }
      });
    }
  }

  void _handleNotificationCreate(Map<String, dynamic> data) {
    // Notify about new notification
    if (onNewNotification != null) {
      onNewNotification!(data);
    }

    // Update unread count
    if (onUnreadCountUpdate != null && !_hasMaxCount) {
      _debounceRefresh(() {
        if (onUnreadCountUpdate != null) {
          onUnreadCountUpdate!(-1); // -1 means "refresh via API"
        }
      });
    }
  }

  void _handleNotificationRead(Map<String, dynamic> data) {
    if (onUnreadCountUpdate != null && !_hasMaxCount) {
      _debounceRefresh(() {
        if (onUnreadCountUpdate != null) {
          onUnreadCountUpdate!(-1);
        }
      });
    }
  }

  void _handleNotificationReadAll(Map<String, dynamic> data) {
    if (onUnreadCountUpdate != null) {
      onUnreadCountUpdate!(0);
    }
  }

  void _handleNotificationDelete(Map<String, dynamic> data) {
    if (onUnreadCountUpdate != null && !_hasMaxCount) {
      _debounceRefresh(() {
        if (onUnreadCountUpdate != null) {
          onUnreadCountUpdate!(-1);
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

  // Set max count flag
  void setMaxCount(bool hasMaxCount) {
    _hasMaxCount = hasMaxCount;
  }

  // Cleanup
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _wsManager.disconnectFromNamespace('notifications');
  }
}
