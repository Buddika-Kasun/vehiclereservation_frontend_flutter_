// lib/services/ws/namespace_websocket_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'namespace_websocket_service.dart';

class NamespaceWebSocketManager {
  static final NamespaceWebSocketManager _instance =
      NamespaceWebSocketManager._internal();
  factory NamespaceWebSocketManager() => _instance;
  NamespaceWebSocketManager._internal();

  final Map<String, NamespaceWebSocketService> _services = {};
  final Map<String, Map<String, Function(Map<String, dynamic>)>> _eventListeners = {};
  final Map<String, Map<String, Function(bool)>> _connectionListeners = {};

  String? _currentUserId;
  String? _currentToken;

  // Initialize connection for a specific namespace
  Future<void> initializeNamespace(String namespace, String token, String userId) async {
    _currentUserId = userId;
    _currentToken = token;

    if (_services.containsKey(namespace)) {
      if (_services[namespace]!.isConnected) {
        if (kDebugMode) {
          print('🌐 Namespace $namespace already connected');
        }
        return;
      } else {
        await _services[namespace]!.disconnect();
        _services.remove(namespace);
      }
    }

    if (kDebugMode) {
      print('🚀 Initializing namespace WebSocket for $namespace');
    }

    final service = NamespaceWebSocketService(namespace);
    _services[namespace] = service;

    // Setup listeners before connecting
    _setupNamespaceListeners(namespace);

    try {
      await service.connect(token, userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize namespace $namespace: $e');
      }
      rethrow;
    }
  }

  void _setupNamespaceListeners(String namespace) {
    final service = _services[namespace]!;
    final eventListeners = _eventListeners.putIfAbsent(namespace, () => {});
    final connectionListeners = _connectionListeners.putIfAbsent(namespace, () => {});

    // Listen for connection status
    service.connectionStatusStream.listen((isConnected) {
      if (kDebugMode) {
        print('🌐 Namespace $namespace connection: $isConnected');
      }
      connectionListeners.forEach((id, listener) {
        try {
          listener(isConnected);
        } catch (e) {
          if (kDebugMode) {
            print('Error in connection listener $id for namespace $namespace: $e');
          }
        }
      });
    });

    // Listen for events
    service.eventStream.listen((event) {
      eventListeners.forEach((id, listener) {
        try {
          listener(event);
        } catch (e) {
          if (kDebugMode) {
            print('Error in event listener $id for namespace $namespace: $e');
          }
        }
      });
    });
  }

  // Event listeners
  void addEventListener(String namespace, String id, Function(Map<String, dynamic>) listener) {
    _eventListeners.putIfAbsent(namespace, () => {})[id] = listener;
  }

  void removeEventListener(String namespace, String id) {
    _eventListeners[namespace]?.remove(id);
  }

  // Connection listeners
  void addConnectionListener(String namespace, String id, Function(bool) listener) {
    _connectionListeners.putIfAbsent(namespace, () => {})[id] = listener;
    // Immediately notify current state
    if (_services.containsKey(namespace)) {
      listener(_services[namespace]!.isConnected);
    } else {
      listener(false);
    }
  }

  void removeConnectionListener(String namespace, String id) {
    _connectionListeners[namespace]?.remove(id);
  }

  // WebSocket actions
  void emit(String namespace, String event, [dynamic data]) {
    if (_services.containsKey(namespace)) {
      _services[namespace]!.emit(event, data);
    } else {
      if (kDebugMode) {
        print('⚠️ Namespace $namespace not initialized');
      }
    }
  }

  void joinRoom(String namespace, String room) {
    if (_services.containsKey(namespace)) {
      _services[namespace]!.joinRoom(room);
    }
  }

  void leaveRoom(String namespace, String room) {
    if (_services.containsKey(namespace)) {
      _services[namespace]!.leaveRoom(room);
    }
  }

  Future<void> disconnectNamespace(String namespace) async {
    if (_services.containsKey(namespace)) {
      await _services[namespace]!.disconnect();
      _services.remove(namespace);
      _eventListeners.remove(namespace);
      _connectionListeners.remove(namespace);
    }
  }

  Future<void> disconnectAll() async {
    final namespaces = List<String>.from(_services.keys);
    for (final namespace in namespaces) {
      await disconnectNamespace(namespace);
    }
    _currentUserId = null;
    _currentToken = null;
  }

  // Getters
  bool isNamespaceConnected(String namespace) {
    return _services.containsKey(namespace) && _services[namespace]!.isConnected;
  }

  String? getNamespaceSocketId(String namespace) {
    return _services[namespace]?.socketId;
  }

  Map<String, dynamic> getConnectionInfo() {
    final info = <String, dynamic>{
      'userId': _currentUserId,
      'connectedNamespaces': <String, bool>{},
    };

    _services.forEach((namespace, service) {
      info['connectedNamespaces'][namespace] = service.isConnected;
    });

    return info;
  }

  bool isInitializedForUser(String userId) {
    return _currentUserId == userId;
  }
}
