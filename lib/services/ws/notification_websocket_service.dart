import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:vehiclereservation_frontend_flutter_/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/config/websocket_config.dart';

class NotificationWebSocketService {
  static final NotificationWebSocketService _instance =
      NotificationWebSocketService._internal();
  factory NotificationWebSocketService() => _instance;
  NotificationWebSocketService._internal();

  IO.Socket? _socket;
  StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  String? _userId;
  String? _token;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  int _unreadCount = 0;

  // Initialize Socket.IO connection
  Future<void> connect(String token, String userId) async {
    if (_isConnecting) return;

    if (_socket != null) {
      await disconnect();
    }

    _userId = userId;
    _token = token;
    _isConnecting = true;
    _connectionStatusController.add(false);

    try {
      await ApiConfig.init();

      if (WebSocketConfig.debugMode) {
        print('🔌 Connecting to WebSocket at: ${WebSocketConfig.socketIoUrl}');
        print('User ID: $userId');
      }

      _socket = IO.io(
        WebSocketConfig.socketIoUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'token': token, 'userId': userId})
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .enableForceNew()
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
      await _waitForConnection();
    } catch (e) {
      _isConnecting = false;
      _connectionStatusController.add(false);

      if (WebSocketConfig.debugMode) {
        print('❌ Socket.IO connection failed: $e');
      }
      _scheduleReconnect();
    }
  }

  void _setupEventListeners() {
    // Connection events
    _socket!.onConnect((_) {
      if (WebSocketConfig.debugMode) {
        print('✅ Socket.IO connected successfully');
      }

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);

      _notificationStreamController.add({
        'type': 'connected',
        'socketId': _socket!.id,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _requestInitialData();
    });

    _socket!.onDisconnect((_) {
      if (WebSocketConfig.debugMode) {
        print('❌ Socket.IO disconnected');
      }

      _isConnected = false;
      _connectionStatusController.add(false);
      _notificationStreamController.add({
        'type': 'disconnected',
        'timestamp': DateTime.now().toIso8601String(),
      });

      _scheduleReconnect();
    });

    _socket!.onError((data) {
      if (WebSocketConfig.debugMode) {
        print('⚠️ Socket.IO error: $data');
      }
    });

    // Custom events
    _socket!.on('notification', _handleNotification);
    _socket!.on('connected', _handleConnected);
    _socket!.on('user-approved', _handleUserApproved);
    _socket!.on('user-registered', _handleUserRegistered);
    _socket!.on('mark-as-read-response', _handleMarkAsReadResponse);
    _socket!.on('all-read-response', _handleAllReadResponse);
    _socket!.on('pong', _handlePong);
    _socket!.on('initial-notifications', _handleInitialNotifications);
    _socket!.on('unread-count', _handleUnreadCount);
    _socket!.on(
      'delete-notification-response',
      _handleDeleteNotificationResponse,
    );
    _socket!.on('clear-all-notifications-response', _handleClearAllResponse);
  }

  void _requestInitialData() {
    if (_socket != null && _isConnected) {
      if (WebSocketConfig.debugMode) {
        print('📤 Requesting initial notifications and unread count');
      }
      _socket!.emit('get-initial-notifications', {});
      _socket!.emit('get-unread-count', {});
    }
  }

  // Event handlers
  void _handleNotification(dynamic data) {
    if (WebSocketConfig.debugMode) {
      print('📨 Received notification: $data');
    }

    final notification = Map<String, dynamic>.from(data as Map);
    final isPending = notification['isPending'] == true;

    if (!isPending) {
      _unreadCount++;
      _unreadCountController.add(_unreadCount);
    }

    _notificationStreamController.add({
      'type': 'new_notification',
      'data': notification,
      'isPending': isPending,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleConnected(dynamic data) {
    if (WebSocketConfig.debugMode) {
      print('🔌 WebSocket connected event received: $data');
    }
  }

  void _handleUserApproved(dynamic data) {
    final notification = Map<String, dynamic>.from(data as Map);
    _notificationStreamController.add({
      'type': 'user_approved',
      'data': notification,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleUserRegistered(dynamic data) {
    final notification = Map<String, dynamic>.from(data as Map);
    _notificationStreamController.add({
      'type': 'user_registered',
      'data': notification,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleMarkAsReadResponse(dynamic data) {
    final response = Map<String, dynamic>.from(data as Map);
    if (response['success'] == true) {
      if (_unreadCount > 0) {
        _unreadCount--;
        _unreadCountController.add(_unreadCount);
      }

      _notificationStreamController.add({
        'type': 'notification_read',
        'data': {'notificationId': response['notificationId']},
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handleAllReadResponse(dynamic data) {
    final response = Map<String, dynamic>.from(data as Map);
    if (response['success'] == true) {
      _unreadCount = 0;
      _unreadCountController.add(_unreadCount);
      _notificationStreamController.add({
        'type': 'all_read',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handlePong(dynamic data) {
    if (WebSocketConfig.debugMode) {
      print('🏓 Received pong');
    }
  }

  void _handleInitialNotifications(dynamic data) {
    if (WebSocketConfig.debugMode) {
      print('📊 Received initial-notifications event');
      print('📊 Data type: ${data.runtimeType}');
      print('📊 Data content: $data');
    }

    try {
      // The data comes directly as the payload from Socket.IO
      final response = Map<String, dynamic>.from(data as Map);

      if (WebSocketConfig.debugMode) {
        print('📦 Parsed response keys: ${response.keys}');
        print(
          '📦 Notifications count: ${(response['notifications'] as List?)?.length ?? 0}',
        );
        print('📦 Unread count: ${response['unreadCount']}');
      }

      final unread = response['unreadCount'] ?? 0;
      _unreadCount = unread;
      _unreadCountController.add(_unreadCount);

      // Pass the data EXACTLY as received - don't wrap it again!
      _notificationStreamController.add({
        'type': 'initial-notifications',
        'data':
            response, // Pass the entire response with notifications and unreadCount
      });

      if (WebSocketConfig.debugMode) {
        print('✅ Emitted initial-notifications to stream');
      }
    } catch (e) {
      if (WebSocketConfig.debugMode) {
        print('❌ Error handling initial notifications: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
    }
  }

  void _handleUnreadCount(dynamic data) {
    if (WebSocketConfig.debugMode) {
      print('📊 Received unread-count event: $data');
    }

    try {
      final response = Map<String, dynamic>.from(data as Map);
      final unread = response['count'] ?? 0;

      _unreadCount = unread;
      _unreadCountController.add(_unreadCount);

      _notificationStreamController.add({
        'type': 'unread-count',
        'data': {'count': unread},
      });

      if (WebSocketConfig.debugMode) {
        print('✅ Updated unread count to: $unread');
      }
    } catch (e) {
      if (WebSocketConfig.debugMode) {
        print('❌ Error handling unread count: $e');
      }
    }
  }

  void _handleDeleteNotificationResponse(dynamic data) {
    final response = Map<String, dynamic>.from(data as Map);
    if (response['success'] == true) {
      if (response['wasUnread'] == true) {
        _unreadCount = (_unreadCount - 1).clamp(0, double.maxFinite).toInt();
        _unreadCountController.add(_unreadCount);
      }

      _notificationStreamController.add({
        'type': 'notification_deleted',
        'data': {'notificationId': response['notificationId']},
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handleClearAllResponse(dynamic data) {
    final response = Map<String, dynamic>.from(data as Map);
    if (response['success'] == true) {
      _unreadCount = 0;
      _unreadCountController.add(_unreadCount);

      _notificationStreamController.add({
        'type': 'all_cleared',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _waitForConnection() async {
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    while (!_isConnected &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!_isConnected) {
      throw TimeoutException('Socket.IO connection timeout');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (WebSocketConfig.debugMode) {
        print('❌ Max reconnect attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: 2 + _reconnectAttempts * 2);

    if (WebSocketConfig.debugMode) {
      print(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
      );
    }

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_isConnected &&
          !_isConnecting &&
          _userId != null &&
          _token != null) {
        connect(_token!, _userId!);
      }
    });
  }

  // Public methods
  void markAsRead(String notificationId) {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Emitting mark-as-read for: $notificationId');
      }
      _socket!.emit('mark-as-read', {'notificationId': notificationId});
    }
  }

  void markAllAsRead() {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Emitting mark-all-read');
      }
      _socket!.emit('mark-all-read', {});
    }
  }

  void deleteNotification(String notificationId) {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Emitting delete-notification for: $notificationId');
      }
      _socket!.emit('delete-notification', {'notificationId': notificationId});
    }
  }

  void clearAllNotifications() {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Emitting clear-all-notifications');
      }
      _socket!.emit('clear-all-notifications', {});
    }
  }

  void ping() {
    if (_isConnected && _socket != null) {
      _socket!.emit('ping', {});
    }
  }

  void joinRoom(String room) {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Joining room: $room');
      }
      _socket!.emit('join-room', {'room': room});
    }
  }

  void leaveRoom(String room) {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Leaving room: $room');
      }
      _socket!.emit('leave-room', {'room': room});
    }
  }

  void getInitialNotifications() {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Requesting initial notifications');
      }
      _socket!.emit('get-initial-notifications', {});
    } else {
      if (WebSocketConfig.debugMode) {
        print('⚠️ Cannot request notifications - not connected');
      }
    }
  }

  void getUnreadCount() {
    if (_isConnected && _socket != null) {
      if (WebSocketConfig.debugMode) {
        print('📤 Requesting unread count');
      }
      _socket!.emit('get-unread-count', {});
    } else {
      if (WebSocketConfig.debugMode) {
        print('⚠️ Cannot request unread count - not connected');
      }
    }
  }

  // Disconnect from server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.clearListeners();
      _socket = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _userId = null;
    _token = null;
    _unreadCount = 0;
    _unreadCountController.add(_unreadCount);
    _connectionStatusController.add(false);

    if (WebSocketConfig.debugMode) {
      print('🔌 Disconnected from WebSocket');
    }
  }

  // Getters
  bool get isConnected => _isConnected;
  int get unreadCount => _unreadCount;
  String? get socketId => _socket?.id;
}
