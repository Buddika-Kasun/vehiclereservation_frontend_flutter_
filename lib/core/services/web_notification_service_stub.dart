// lib/core/services/web_notification_service_stub.dart
import 'package:flutter/foundation.dart';

class WebDeviceRegistration {
  static final WebDeviceRegistration _instance =
      WebDeviceRegistration._internal();
  factory WebDeviceRegistration() => _instance;
  WebDeviceRegistration._internal();

  Future<void> register() async {
    if (!kIsWeb) return;
    // Do nothing on non-web platforms
  }

  Future<void> unregister() async {
    if (!kIsWeb) return;
    // Do nothing on non-web platforms
  }
}
