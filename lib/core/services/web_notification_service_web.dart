// web_device_registration.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';

class WebDeviceRegistration {
  static final WebDeviceRegistration _instance =
      WebDeviceRegistration._internal();
  factory WebDeviceRegistration() => _instance;
  WebDeviceRegistration._internal();

  Future<void> register() async {
    // Only for web
    if (!kIsWeb) return;

    try {
      // Check if user is logged in
      final isLoggedIn = await SecureStorageService().isUserLoggedIn();
      if (!isLoggedIn) return;

      // Get device info
      final deviceId = _getDeviceId();
      final deviceName = _getDeviceName();

      // Send to backend
      await ApiService.registerWebDevice(
        deviceId: deviceId,
        deviceName: deviceName,
      );

      print('✅ Web device registered');
    } catch (e) {
      print('❌ Web device registration error: $e');
    }
  }

  Future<void> unregister() async {
    // Only for web
    if (!kIsWeb) return;

    try {
      // Get device info
      final deviceId = _getDeviceId();

      final user = StorageService.userData;

      // Send to backend
      await ApiService.unregisterWebDevice(
        deviceId: deviceId,
        userId: user?.id,
      );

      print('✅ Web device unregistered');
    } catch (e) {
      print('❌ Web device unregistration error: $e');
    }
  }

  String _getDeviceId() {
    // Try to get existing ID from localStorage
    final existingId = html.window.localStorage['web_device_id'];
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    // Generate new device ID
    final userAgent = html.window.navigator.userAgent;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceId = 'web_${_hash(userAgent)}_$timestamp';

    // Save to localStorage
    html.window.localStorage['web_device_id'] = deviceId;

    return deviceId;
  }

  String _getDeviceName() {
    final userAgent = html.window.navigator.userAgent;

    // Simple browser detection
    if (userAgent.contains('Chrome')) return 'Chrome';
    if (userAgent.contains('Firefox')) return 'Firefox';
    if (userAgent.contains('Safari')) return 'Safari';
    if (userAgent.contains('Edge')) return 'Edge';

    return 'Web Browser';
  }

  String _hash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
    }
    return hash.abs().toString();
  }
}
