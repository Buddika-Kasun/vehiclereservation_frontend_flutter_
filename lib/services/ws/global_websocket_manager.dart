// lib/services/global_websocket_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'notification_websocket_service.dart';

class GlobalWebSocketManager {
  static final GlobalWebSocketManager _instance =
      GlobalWebSocketManager._internal();
  factory GlobalWebSocketManager() => _instance;
  GlobalWebSocketManager._internal();

  final NotificationWebSocketService _webSocketService =
      NotificationWebSocketService();
  final Map<String, Function(bool)> _connectionListeners = {};
  final Map<String, Function(int)> _unreadListeners = {};
  final Map<String, Function(Map<String, dynamic>)> _notificationListeners = {};

  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentToken;

  bool get isConnected => _webSocketService.isConnected;
  int get unreadCount => _webSocketService.unreadCount;
  String? get socketId => _webSocketService.socketId;

  Stream<bool> get connectionStatusStream =>
      _webSocketService.connectionStatusStream;
  Stream<int> get unreadCountStream => _webSocketService.unreadCountStream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _webSocketService.notificationStream;

  Future<void> initialize(String token, String userId) async {
    if (_isInitialized &&
        _currentUserId == userId &&
        _currentToken == token &&
        _webSocketService.isConnected) {
      if (kDebugMode) {
        print('🌐 WebSocket already initialized and connected');
      }
      return;
    }

    _currentUserId = userId;
    _currentToken = token;
    _isInitialized = true;

    if (kDebugMode) {
      print('🚀 Initializing Global WebSocket Manager for user: $userId');
    }

    try {
      // Disconnect existing connection if any
      await _webSocketService.disconnect();

      // Setup listeners before connecting
      _setupServiceListeners();

      // Connect to WebSocket
      await _webSocketService.connect(token, userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Global WebSocket: $e');
      }
      _isInitialized = false;
      rethrow;
    }
  }

  void _setupServiceListeners() {
    // Listen for connection status
    _webSocketService.connectionStatusStream.listen((isConnected) {
      if (kDebugMode) {
        print('🌐 Global connection status: $isConnected');
      }
      _notifyConnectionListeners(isConnected);
    });

    // Listen for unread count
    _webSocketService.unreadCountStream.listen((count) {
      if (kDebugMode) {
        print('📊 Global unread count: $count');
      }
      _notifyUnreadListeners(count);
    });

    // Listen for notifications
    _webSocketService.notificationStream.listen((notification) {
      _notifyNotificationListeners(notification);
    });
  }

  // Connection listeners
  void addConnectionListener(String id, Function(bool) listener) {
    _connectionListeners[id] = listener;
    // Immediately notify current state
    listener(_webSocketService.isConnected);
  }

  void removeConnectionListener(String id) {
    _connectionListeners.remove(id);
  }

  // Unread count listeners
  void addUnreadListener(String id, Function(int) listener) {
    _unreadListeners[id] = listener;
    // Immediately notify current count
    listener(_webSocketService.unreadCount);
  }

  void removeUnreadListener(String id) {
    _unreadListeners.remove(id);
  }

  // Notification listeners
  void addNotificationListener(
    String id,
    Function(Map<String, dynamic>) listener,
  ) {
    _notificationListeners[id] = listener;
  }

  void removeNotificationListener(String id) {
    _notificationListeners.remove(id);
  }

  void _notifyConnectionListeners(bool isConnected) {
    _connectionListeners.forEach((id, listener) {
      try {
        listener(isConnected);
      } catch (e) {
        if (kDebugMode) {
          print('Error in connection listener $id: $e');
        }
      }
    });
  }

  void _notifyUnreadListeners(int count) {
    _unreadListeners.forEach((id, listener) {
      try {
        listener(count);
      } catch (e) {
        if (kDebugMode) {
          print('Error in unread listener $id: $e');
        }
      }
    });
  }

  void _notifyNotificationListeners(Map<String, dynamic> notification) {
    _notificationListeners.forEach((id, listener) {
      try {
        listener(notification);
      } catch (e) {
        if (kDebugMode) {
          print('Error in notification listener $id: $e');
        }
      }
    });
  }

  // WebSocket actions
  void markAsRead(String notificationId) {
    _webSocketService.markAsRead(notificationId);
  }

  void markAllAsRead() {
    _webSocketService.markAllAsRead();
  }

  void joinRoom(String room) {
    // Join a specific room for targeted notifications
    if (_webSocketService.isConnected) {
      // Add this method to NotificationWebSocketService
      // _webSocketService.joinRoom(room);
    }
  }

  Future<void> disconnect() async {
    _isInitialized = false;
    _currentUserId = null;
    _currentToken = null;
    _connectionListeners.clear();
    _unreadListeners.clear();
    _notificationListeners.clear();
    await _webSocketService.disconnect();
  }

  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _webSocketService.isConnected,
      'unreadCount': _webSocketService.unreadCount,
      'socketId': _webSocketService.socketId,
      'isInitialized': _isInitialized,
      'userId': _currentUserId,
    };
  }

  bool isInitializedForUser(String userId) {
    return _isInitialized && _currentUserId == userId;
  }

  void ping() {
    // Send ping to keep connection alive
    if (_webSocketService.isConnected) {
      // Add this method to NotificationWebSocketService
      // _webSocketService.ping();
    }
  }



  void getInitialNotifications() {
    if (_webSocketService.isConnected) {
      // You need to implement this in NotificationWebSocketService
      _webSocketService.getInitialNotifications();
    }
  }

  void getUnreadCount() {
    if (_webSocketService.isConnected) {
      // You need to implement this in NotificationWebSocketService
      _webSocketService.getUnreadCount();
    }
  }

  // Also update the clearAllNotifications and deleteNotification methods:

  void clearAllNotifications() {
    if (_webSocketService.isConnected) {
      // Implement this in NotificationWebSocketService
      _webSocketService.clearAllNotifications();
    }
  }

  void deleteNotification(String notificationId) {
    if (_webSocketService.isConnected) {
      // Implement this in NotificationWebSocketService
      _webSocketService.deleteNotification(notificationId);
    }
  }

}
