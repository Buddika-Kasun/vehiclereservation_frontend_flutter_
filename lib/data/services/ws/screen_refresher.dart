// lib/data/services/ws/screen_refresher.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Common screen refresh logic with debouncing
class ScreenRefresher {
  Timer? _refreshTimer;
  final Duration _debounceDelay;
  final String _screenName;

  // Callback when refresh is needed
  final VoidCallback onRefreshNeeded;

  ScreenRefresher({
    required this.onRefreshNeeded,
    required String screenName,
    Duration debounceDelay = const Duration(milliseconds: 500),
  }) : _debounceDelay = debounceDelay,
       _screenName = screenName;

  /// Request a refresh with debouncing
  void requestRefresh({String? source}) {
    if (_refreshTimer?.isActive ?? false) {
      _refreshTimer?.cancel();
    }

    _refreshTimer = Timer(_debounceDelay, () {
      if (kDebugMode) {
        print('🔄 [$_screenName] Refreshing from ${source ?? 'unknown'}');
      }
      onRefreshNeeded();
    });
  }

  /// Force immediate refresh (without debouncing)
  void forceRefresh() {
    _refreshTimer?.cancel();
    onRefreshNeeded();
  }

  /// Cancel pending refresh
  void cancelRefresh() {
    _refreshTimer?.cancel();
  }

  /// Cleanup
  void dispose() {
    _refreshTimer?.cancel();
  }
}
