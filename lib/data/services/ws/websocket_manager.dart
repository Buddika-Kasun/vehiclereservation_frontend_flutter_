// lib/data/services/ws/websocket_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/websocket_config.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/socketio_client.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  // Track initialization state
  bool _isInitialized = false;

  // Store active connections
  final Map<String, SocketIOClient> _connections = {};

  // Message listeners: namespace -> [listeners]
  final Map<String, List<Function(Map<String, dynamic>)>> _messageListeners =
      {};

  // Connection listeners: namespace -> [listeners]
  final Map<String, List<Function(bool)>> _connectionListeners = {};

  // Global config
  String? _token;
  String? _userId;

  // Track connection usage count
  final Map<String, int> _connectionUsageCount = {};

  // Add this public getter
  SocketIOClient? getConnection(String namespace) {
    return _connections[namespace];
  }

  // Add this to get all events directly
  void listenToRawEvents(String namespace, Function(String, dynamic) handler) {
    final client = _connections[namespace];
    if (client != null) {
      // Add raw event listener to SocketIOClient
      client.listenToAllEvents(handler);
    }
  }

  // Connect to a specific namespace with Socket.IO
  Future<void> connectToNamespace(String namespace) async {
    if (_token == null || _userId == null) {
      throw Exception('WebSocketManager not initialized');
    }

    // Debug log
    if (kDebugMode) {
      print('🔗 connectToNamespace called for: $namespace');
      print('   Current usage count: ${_connectionUsageCount[namespace] ?? 0}');
    }

    // Increment usage count FIRST
    _connectionUsageCount[namespace] =
        (_connectionUsageCount[namespace] ?? 0) + 1;

    if (kDebugMode) {
      print('   New usage count: ${_connectionUsageCount[namespace]}');
    }

    // Check if already connected
    if (_connections.containsKey(namespace) &&
        _connections[namespace]!.isConnected) {
      if (kDebugMode) {
        print('✅ Already connected to $namespace, skipping new connection');
        // SocketIOClient doesn't have an id property, so we can't print it
      }
      return;
    }

    // Clean up old connection if exists but not connected
    if (_connections.containsKey(namespace) &&
        !_connections[namespace]!.isConnected) {
      if (kDebugMode) {
        print('🔄 Cleaning up old disconnected connection for: $namespace');
      }
      await _disconnectFromNamespace(namespace);
    }

    // Only create new connection if needed
    if (!_connections.containsKey(namespace)) {
      await _createConnection(namespace);
    }
  }

  // Create a new connection to a namespace
  Future<void> _createConnection(String namespace) async {
    if (_token == null || _userId == null) {
      throw Exception('WebSocketManager not initialized');
    }

    if (kDebugMode) {
      print('🔗 Creating connection to namespace: $namespace');
      print('   User ID: $_userId');
      print('   Token length: ${_token?.length}');
    }

    // Prepare query parameters
    final queryParams = {
      'userId': _userId,
      'token': _token,
      'userRoom': 'user_$_userId',
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (kDebugMode) {
      print('📤 Query params for $namespace:');
      queryParams.forEach((key, value) {
        if (key == 'token') {
          print(
            '   $key: ...${value.toString().substring(value.toString().length - 10)}',
          );
        } else {
          print('   $key: $value');
        }
      });
    }

    // Create Socket.IO client WITH query parameters
    final client = SocketIOClient(
      namespace: namespace,
      baseUrl: WebSocketConfig.socketIoUrl,
      options: WebSocketConfig.connectionOptions,
      queryParams: queryParams, // Pass query params here
    );

    _connections[namespace] = client;

    // Listen for messages
    client.messageStream.listen((message) {
      if (kDebugMode) {
        print('📨 Raw message from SocketIOClient for $namespace: $message');
      }
      _handleIncomingMessage(namespace, message);
    });

    // Listen for connection changes
    client.connectionStream.listen((isConnected) {
      if (kDebugMode) {
        print('🔌 Connection stream for $namespace: $isConnected');
      }
      _notifyConnectionListeners(namespace, isConnected);
    });

    // Connect (no need to pass query params again)
    await client.connect();

    if (kDebugMode) {
      print('✅ Connected to namespace: $namespace as user_$_userId');
    }
  }

  // Initialize with user info
  void initialize({required String token, required String userId}) {
    // Don't reinitialize if already initialized with same credentials
    if (_isInitialized && _token == token && _userId == userId) {
      if (kDebugMode) {
        print('ℹ️ WebSocketManager already initialized');
      }
      return;
    }

    _token = token;
    _userId = userId;
    _isInitialized = true;

    if (kDebugMode) {
      print('🚀 WebSocketManager initialized for user: $userId');
    }
  }

  // Disconnect from namespace with reference counting
  Future<void> disconnectFromNamespace(String namespace) async {
    if (!_connectionUsageCount.containsKey(namespace)) {
      return;
    }

    // Decrement usage count
    _connectionUsageCount[namespace] = _connectionUsageCount[namespace]! - 1;

    // Only disconnect if no one is using it
    if (_connectionUsageCount[namespace]! <= 0) {
      _connectionUsageCount.remove(namespace);
      await _disconnectFromNamespace(namespace);
      _messageListeners.remove(namespace);
      _connectionListeners.remove(namespace);

      if (kDebugMode) {
        print('🔌 Disconnected from namespace: $namespace');
      }
    } else {
      if (kDebugMode) {
        print(
          'ℹ️ Keeping namespace connection alive (${_connectionUsageCount[namespace]} users)',
        );
      }
    }
  }

  // Check if namespace has active users
  bool hasActiveUsers(String namespace) {
    return (_connectionUsageCount[namespace] ?? 0) > 0;
  }

  void _handleIncomingMessage(String namespace, Map<String, dynamic> message) {
    final event = message['event']?.toString() ?? '';

    if (kDebugMode) {
      print('📨 [$namespace] Event: $event');
    }

    // Notify all listeners for this namespace
    if (_messageListeners.containsKey(namespace)) {
      for (final listener in _messageListeners[namespace]!) {
        listener(message);
      }
    }
  }

  void _notifyConnectionListeners(String namespace, bool isConnected) {
    if (_connectionListeners.containsKey(namespace)) {
      for (final listener in _connectionListeners[namespace]!) {
        listener(isConnected);
      }
    }
  }

  // Add message listener for a namespace
  void addMessageListener(
    String namespace,
    Function(Map<String, dynamic>) listener,
  ) {
    if (!_messageListeners.containsKey(namespace)) {
      _messageListeners[namespace] = [];
    }
    _messageListeners[namespace]!.add(listener);
  }

  // Add connection listener for a namespace
  void addConnectionListener(String namespace, Function(bool) listener) {
    if (!_connectionListeners.containsKey(namespace)) {
      _connectionListeners[namespace] = [];
    }
    _connectionListeners[namespace]!.add(listener);
  }

  // Remove message listener
  void removeMessageListener(
    String namespace,
    Function(Map<String, dynamic>) listener,
  ) {
    if (_messageListeners.containsKey(namespace)) {
      _messageListeners[namespace]!.remove(listener);
    }
  }

  // Remove connection listener
  void removeConnectionListener(String namespace, Function(bool) listener) {
    if (_connectionListeners.containsKey(namespace)) {
      _connectionListeners[namespace]!.remove(listener);
    }
  }

  // Check if namespace is connected
  bool isNamespaceConnected(String namespace) {
    return _connections[namespace]?.isConnected ?? false;
  }

  // Get connection info
  Map<String, dynamic> getConnectionInfo(String namespace) {
    final client = _connections[namespace];
    return {
      'isConnected': client?.isConnected ?? false,
      'namespace': namespace,
      'userId': _userId,
    };
  }

  // Private disconnect
  Future<void> _disconnectFromNamespace(String namespace) async {
    final client = _connections[namespace];
    if (client != null) {
      await client.disconnect();
      _connections.remove(namespace);

      if (kDebugMode) {
        print('🔌 Disconnected from namespace: $namespace');
      }
    }
  }

  // Cleanup all connections
  Future<void> disconnectAll() async {
    final futures = _connections.values.map((client) => client.disconnect());
    await Future.wait(futures);
    _connections.clear();
    _messageListeners.clear();
    _connectionListeners.clear();

    if (kDebugMode) {
      print('🔄 All Socket.IO connections closed');
    }
  }

  // Emit event to namespace
  void emit(String namespace, String event, dynamic data) {
    final client = _connections[namespace];
    if (client != null && client.isConnected) {
      client.emit(event, data);
    } else {
      if (kDebugMode) {
        print('⚠️ Cannot emit to $namespace, not connected');
      }
    }
  }

  // Print connection status for debugging
  void printConnectionStatus() {
    if (kDebugMode) {
      print('📊 ========== WebSocket Connection Status ==========');
      print('   Initialized: $_isInitialized');
      print('   Token: ${_token?.substring(_token!.length - 10)}...');
      print('   User ID: $_userId');
      print('   Active connections: ${_connections.length}');

      _connections.forEach((namespace, client) {
        print('   $namespace: Connected=${client.isConnected}');
      });

      print('   Usage counts:');
      _connectionUsageCount.forEach((namespace, count) {
        print('     $namespace: $count users');
      });

      print('===================================================');
    }
  }

  static WebSocketManager get instance => _instance;
}
