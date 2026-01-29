// lib/data/services/ws/socketio_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../config/websocket_config.dart';

class SocketIOClient {
  io.Socket? _socket;
  final String _namespace;
  final String _url;
  final Map<String, dynamic> _options;
  Map<String, dynamic>? _queryParams;

  StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController.broadcast();
  StreamController<bool> _connectionStreamController =
      StreamController.broadcast();
  StreamController<String> _eventStreamController =
      StreamController.broadcast();

  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  SocketIOClient({
    required String namespace,
    required String baseUrl,
    Map<String, dynamic>? options,
    Map<String, dynamic>? queryParams,
  }) : _namespace = namespace,
       _url = baseUrl,
       _options = options ?? WebSocketConfig.connectionOptions,
       _queryParams = queryParams {
    _setupSocket();
  }

  void _setupSocket() {
    final url = '$_url/$_namespace';

    if (kDebugMode) {
      print('🔌 Creating Socket.IO connection to: $url');
      if (_queryParams != null) {
        print('   With query params: $_queryParams');
      }
    }

    // Create options with query params
    final optionsBuilder = io.OptionBuilder()
        .setTransports(_options['transports'] ?? ['websocket'])
        .setPath(_options['path'] ?? '/socket.io')
        .enableReconnection()
        .setReconnectionAttempts(_options['reconnectionAttempts'] ?? 5)
        .setReconnectionDelay(_options['reconnectionDelay'] ?? 1000)
        .setReconnectionDelayMax(_options['reconnectionDelayMax'] ?? 5000)
        .setTimeout(_options['timeout'] ?? 30000);

    // Add query parameters to options
    if (_queryParams != null) {
      // Convert to Map<String, dynamic> for Socket.IO
      final queryMap = <String, dynamic>{};
      _queryParams!.forEach((key, value) {
        queryMap[key] = value;
      });
      optionsBuilder.setExtraHeaders({'query': jsonEncode(queryMap)});

      // Also set query directly
      optionsBuilder.setQuery(queryMap);
    }

    // Create Socket.IO client with options
    _socket = io.io(url, optionsBuilder.build());

    _setupEventListeners();
  }

  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  Stream<String> get eventStream => _eventStreamController.stream;
  bool get isConnected => _isConnected;

  void onRawEvent(Function(String, dynamic) handler) {
    if (_socket != null) {
      _socket!.onAny((event, data) {
        handler(event, data);
      });
    }
  }

  
  void _setupEventListeners() {
    _socket!.onConnect((_) {
      _handleConnect();
    });

    _socket!.onDisconnect((_) {
      _handleDisconnect();
    });

    _socket!.onError((data) {
      _handleError(data);
    });

    // Listen for custom events
    _socket!.onAny((event, data) {
      _handleEvent(event, data);
    });
  }

  void _handleConnect() {
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    _connectionStreamController.add(true);
    _eventStreamController.add('connected');

    if (kDebugMode) {
      print('✅ Socket.IO connected to: $_namespace');
      print('   Socket ID: ${_socket!.id}');
    }
  }

  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      _connectionStreamController.add(false);
      _eventStreamController.add('disconnected');

      if (kDebugMode) {
        print('🔌 Socket.IO disconnected from: $_namespace');
      }

      if (_reconnectAttempts < _maxReconnectAttempts) {
        _scheduleReconnect();
      }
    }
  }

  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('❌ Socket.IO error on $_namespace: $error');
    }
    _eventStreamController.add('error');
  }

  // In SocketIOClient, update the _handleEvent method:
  // In SocketIOClient class, add this method:
  void listenToAllEvents(Function(String, dynamic) handler) {
    if (_socket != null) {
      _socket!.onAny((event, data) {
        if (kDebugMode) {
          print('🎯 RAW Socket.IO Event: $event');
          print('🎯 RAW Socket.IO Data: $data');
        }
        handler(event, data);
      });
    }
  }

  // Also update the _handleEvent method to log more details:
  void _handleEvent(String event, dynamic data) {
    try {
      if (kDebugMode) {
        print('🎯 [$_namespace] Processing event: $event');
        print('🎯 [$_namespace] Raw data type: ${data.runtimeType}');
        print('🎯 [$_namespace] Raw data: $data');

        // Check if it's a notification_update event
        if (event == 'notification_update') {
          print('🎯 [$_namespace] THIS IS A NOTIFICATION_UPDATE EVENT!');
          print('🎯 [$_namespace] Data structure:');
          if (data is Map) {
            data.forEach((key, value) {
              print('      $key: $value (${value.runtimeType})');
            });
          }
        }
      }

      final message = {
        'event': event,
        'data': data,
        'namespace': _namespace,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _messageStreamController.add(message);
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error handling Socket.IO event: $error');
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('❌ Max reconnection attempts reached for $_namespace');
      }
      return;
    }

    _reconnectAttempts++;
    final delay =
        Duration(milliseconds: _options['reconnectionDelay'] ?? 1000) *
        _reconnectAttempts;

    _reconnectTimer = Timer(delay, () {
      if (kDebugMode) {
        print(
          '🔄 Attempting to reconnect $_namespace (attempt $_reconnectAttempts)...',
        );
      }
      connect();
    });
  }

  // In SocketIOClient.connect method, ensure query params are being set:
  Future<void> connect({Map<String, dynamic>? queryParams}) async {
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    _connectionStreamController.add(false);

    try {
      // Add query parameters if provided
      if (queryParams != null && _socket != null) {
        if (kDebugMode) {
          print('🔗 Setting query params: $queryParams');
        }
        // Clear existing query first
        _socket!.io.options?['query'] = null;
        // Set new query params
        _socket!.io.options?['query'] = queryParams;
      }

      if (kDebugMode) {
        print('🚀 Connecting to namespace: $_namespace');
        print('   Query params: ${_socket?.io.options?['query']}');
      }

      _socket!.connect();
    } catch (error) {
      // ... error handling ...
    }
  }

  

  void emit(String event, dynamic data) {
    if (_isConnected && _socket != null) {
      try {
        _socket!.emit(event, data);

        if (kDebugMode) {
          print('📤 [$_namespace] Emitting: $event');
        }
      } catch (error) {
        if (kDebugMode) {
          print('❌ Error emitting Socket.IO event: $error');
        }
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Cannot emit event, Socket.IO not connected to $_namespace');
      }
    }
  }

  void on(String event, Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    }
  }

  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts;

    try {
      _socket?.disconnect();
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error disconnecting Socket.IO: $error');
      }
    }

    _isConnected = false;
    _isConnecting = false;
    _connectionStreamController.add(false);

    await _messageStreamController.close();
    await _connectionStreamController.close();
    await _eventStreamController.close();
  }

  String get namespace => _namespace;
}
