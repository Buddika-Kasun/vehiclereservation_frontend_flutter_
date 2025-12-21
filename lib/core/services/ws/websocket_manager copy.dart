// lib/data/services/ws/websocket_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/websocket_config.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/socketio_client.dart';

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

  // Connect to a specific namespace with Socket.IO
  Future<void> connectToNamespace(String namespace) async {
    if (_token == null || _userId == null) {
      throw Exception('WebSocketManager not initialized');
    }

    // Check if already connected
    if (_connections.containsKey(namespace) &&
        _connections[namespace]!.isConnected) {
      if (kDebugMode) {
        print('ℹ️ Already connected to namespace: $namespace');
      }
      return;
    }

    // Clean up old connection if exists
    if (_connections.containsKey(namespace)) {
      await _disconnectFromNamespace(namespace);
    }

    // Create Socket.IO client
    final client = SocketIOClient(
      namespace: namespace,
      baseUrl: WebSocketConfig.socketIoUrl,
      options: WebSocketConfig.connectionOptions,
    );

    _connections[namespace] = client;

    // Listen for messages
    client.messageStream.listen((message) {
      _handleIncomingMessage(namespace, message);
    });

    // Listen for connection changes
    client.connectionStream.listen((isConnected) {
      _notifyConnectionListeners(namespace, isConnected);
    });

    // Connect with query parameters
    await client.connect(queryParams: {'userId': _userId, 'token': _token});

    if (kDebugMode) {
      print('✅ Connected to namespace: $namespace');
    }
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

  // Disconnect from namespace
  Future<void> disconnectFromNamespace(String namespace) async {
    await _disconnectFromNamespace(namespace);
    _messageListeners.remove(namespace);
    _connectionListeners.remove(namespace);
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

  static WebSocketManager get instance => _instance;
  
}
