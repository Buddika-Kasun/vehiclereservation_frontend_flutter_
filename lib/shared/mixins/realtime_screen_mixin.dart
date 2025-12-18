// lib/mixins/realtime_screen_mixin.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/namespace_websocket_manager.dart';

mixin RealtimeScreenMixin<T extends StatefulWidget> on State<T> {
  final NamespaceWebSocketManager _webSocketManager = NamespaceWebSocketManager();
  final String _screenRefreshListenerId = UniqueKey().toString();
  bool _isScreenRefreshEnabled = false;

  // Override this in your screen to specify the namespace
  String get namespace;

  @override
  void initState() {
    super.initState();
    _enableScreenRefresh();
  }

  @override
  void dispose() {
    _disableScreenRefresh();
    super.dispose();
  }

  void _enableScreenRefresh() {
    if (!_isScreenRefreshEnabled) {
      _webSocketManager.addEventListener(
        namespace,
        _screenRefreshListenerId,
        _handleRealtimeUpdate,
      );
      _isScreenRefreshEnabled = true;
      if (kDebugMode) {
        print('🔄 Screen refresh enabled for ${runtimeType} on namespace $namespace');
      }
    }
  }

  void _disableScreenRefresh() {
    if (_isScreenRefreshEnabled) {
      _webSocketManager.removeEventListener(namespace, _screenRefreshListenerId);
      _isScreenRefreshEnabled = false;
      if (kDebugMode) {
        print('🔄 Screen refresh disabled for ${runtimeType}');
      }
    }
  }

  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'refresh':
      case 'screen-refresh':
        handleScreenRefresh(data['data'] ?? data);
        break;
      case 'user_registered':
        _handleUserRegisteredUpdate(data);
        break;
      case 'user_approved':
        _handleUserApprovedUpdate(data);
        break;
      case 'user_updated':
        _handleUserUpdatedUpdate(data);
        break;
    }
  }

  // Override these methods in your screen
  @protected
  void handleScreenRefresh(Map<String, dynamic> data) {
    // Default implementation - override in your screen
    if (kDebugMode) {
      print('📱 Screen refresh received: ${data['screen']}');
    }
  }

  void _handleUserRegisteredUpdate(Map<String, dynamic> data) {
    // Handle new user registration
  }

  void _handleUserApprovedUpdate(Map<String, dynamic> data) {
    // Handle user approval
  }

  void _handleUserUpdatedUpdate(Map<String, dynamic> data) {
    // Handle user updates
  }

  // Helper method to request screen refresh from server
  void requestScreenRefresh(String screenPath) {
    // You can implement WebSocket event for requesting refresh
    if (kDebugMode) {
      print('🔄 Requesting screen refresh for: $screenPath');
    }
  }
}

