// lib/utils/websocket_navigator_observer.dart - SIMPLIFIED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class WebSocketNavigatorObserver extends NavigatorObserver {
  WebSocketNavigatorObserver();

  @override
  void didPush(Route route, Route? previousRoute) {
    if (kDebugMode) {
      print('🔄 Pushed route: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (kDebugMode) {
      print('🔄 Popped route: ${route.settings.name}');
    }
  }
}
