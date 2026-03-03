import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedDeviceId; // Cache in memory for the session

  // Private constructor to prevent instantiation
  DeviceHelper._();

  /// Get or create unique device ID
  static Future<String> getDeviceId() async {
    // Return cached ID if available
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    // Generate new device ID
    _cachedDeviceId = await _generateDeviceId();
    return _cachedDeviceId!;
  }

  /// Generate unique device ID based on platform
  static Future<String> _generateDeviceId() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor ?? _generateRandomId()}';
      } else if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (!kIsWeb && Platform.isWindows) {
        return 'windows_${_generateWindowsDeviceId()}';
      } else if (!kIsWeb && Platform.isMacOS) {
        return 'macos_${_generateMacOSDeviceId()}';
      } else if (!kIsWeb && Platform.isLinux) {
        return 'linux_${_generateLinuxDeviceId()}';
      } else {
        // Web or other platforms
        return 'web_${_generateWebDeviceId()}';
      }
    } catch (e) {
      print('❌ Error getting device info: $e');
      return 'unknown_${_generateRandomId()}';
    }
  }

  /// Generate random ID as fallback
  static String _generateRandomId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  /// Generate Windows device ID
  static String _generateWindowsDeviceId() {
    // Use hostname + random as Windows doesn't have a unique identifier
    final hostname = Platform.localHostname;
    return '${hostname}_${_generateRandomId()}';
  }

  /// Generate macOS device ID
  static String _generateMacOSDeviceId() {
    // Use hostname + random as fallback
    final hostname = Platform.localHostname;
    return '${hostname}_${_generateRandomId()}';
  }

  /// Generate Linux device ID
  static String _generateLinuxDeviceId() {
    // Use hostname + random as fallback
    final hostname = Platform.localHostname;
    return '${hostname}_${_generateRandomId()}';
  }

  /// Generate Web device ID
  static String _generateWebDeviceId() {
    // For web, generate a random ID that persists for the session only
    // You can enhance this with browser fingerprinting if needed
    return _generateRandomId();
  }

  /// Get device name/model for display
  static Future<String> getDeviceName() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (!kIsWeb && Platform.isWindows) {
        return 'Windows ${Platform.operatingSystemVersion}';
      } else if (!kIsWeb && Platform.isMacOS) {
        return 'macOS ${Platform.operatingSystemVersion}';
      } else if (!kIsWeb && Platform.isLinux) {
        return 'Linux ${Platform.operatingSystemVersion}';
      } else {
        return _getWebDeviceName();
      }
    } catch (e) {
      print('❌ Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  /// Get web browser name
  static String _getWebDeviceName() {
    // For web, try to get browser info
    // You can use package like `universal_html` for better browser detection
    return 'Web Browser';
  }

  /// Get device type identifier
  static String getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Get platform name for display
  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }

  /// Check if running on mobile
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if running on desktop
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Clear cached device ID (useful for testing or logout)
  static void clearDeviceId() {
    _cachedDeviceId = null;
  }

  /// Get all device information as a map
  static Future<Map<String, dynamic>> getAllDeviceInfo() async {
    return {
      'deviceId': await getDeviceId(),
      'deviceName': await getDeviceName(),
      'deviceType': getDeviceType(),
      'platformName': getPlatformName(),
      'isMobile': isMobile,
      'isDesktop': isDesktop,
      'isWeb': isWeb,
      'operatingSystem': kIsWeb ? 'web' : Platform.operatingSystem,
      'operatingSystemVersion': kIsWeb
          ? 'web'
          : Platform.operatingSystemVersion,
      'localhostname': kIsWeb ? 'web' : Platform.localHostname,
    };
  }
}
