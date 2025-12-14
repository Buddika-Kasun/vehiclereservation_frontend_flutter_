// lib/mixins/realtime_screen_mixin.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/ws/global_websocket_manager.dart';

mixin RealtimeScreenMixin<T extends StatefulWidget> on State<T> {
  final GlobalWebSocketManager _webSocketManager = GlobalWebSocketManager();
  final String _screenRefreshListenerId = UniqueKey().toString();
  bool _isScreenRefreshEnabled = false;

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
      _webSocketManager.addNotificationListener(
        _screenRefreshListenerId,
        _handleRealtimeUpdate,
      );
      _isScreenRefreshEnabled = true;
      if (kDebugMode) {
        print('🔄 Screen refresh enabled for ${runtimeType}');
      }
    }
  }

  void _disableScreenRefresh() {
    if (_isScreenRefreshEnabled) {
      _webSocketManager.removeNotificationListener(_screenRefreshListenerId);
      _isScreenRefreshEnabled = false;
      if (kDebugMode) {
        print('🔄 Screen refresh disabled for ${runtimeType}');
      }
    }
  }

  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'screen-refresh':
        _handleScreenRefresh(data);
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
  void _handleScreenRefresh(Map<String, dynamic> data) {
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
