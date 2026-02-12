// lib/core/services/pending_navigation_service.dart
import 'package:flutter/material.dart';

class PendingNavigationService {
  static final PendingNavigationService _instance =
      PendingNavigationService._internal();
  factory PendingNavigationService() => _instance;
  PendingNavigationService._internal();

  Map<String, dynamic>? _pendingNotification;
  bool _isNavigating = false;

  void setPendingNotification(Map<String, dynamic> data) {
    _pendingNotification = data;
    print("📦 Pending notification stored: ${data['type']}");
  }

  Map<String, dynamic>? getPendingNotification() {
    return _pendingNotification;
  }

  void clearPendingNotification() {
    _pendingNotification = null;
    _isNavigating = false;
  }

  bool get isNavigating => _isNavigating;
  set isNavigating(bool value) => _isNavigating = value;
}
