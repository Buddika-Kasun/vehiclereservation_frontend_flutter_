// lib/core/utils/optional_permission_manager.dart
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class OptionalPermissionManager {
  // Camera permission (for QR scan, document upload)
  static Future<bool> requestCameraPermission({
    BuildContext? context,
    String? rationaleMessage,
  }) async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    // Show rationale dialog if permission was denied before
    if (status.isDenied) {
      if (rationaleMessage != null && context != null && context.mounted) {
        final shouldRequest = await _showPermissionRequestDialog(
          context,
          title: 'Camera Access Required',
          message: rationaleMessage,
        );
        if (!shouldRequest) return false;
      }
    }

    // Request permission directly
    final result = await Permission.camera.request();

    if (result.isPermanentlyDenied && context != null && context.mounted) {
      // Only show settings dialog if permanently denied
      return await _showSettingsDialog(
        context,
        title: 'Camera Permission Required',
        message:
            'Camera access is permanently denied. Please enable it in app settings.',
      );
    }

    return result.isGranted;
  }

  // Storage permission (for file uploads)
  static Future<bool> requestStoragePermission({
    BuildContext? context,
    String? rationaleMessage,
  }) async {
    Permission permission;

    // Handle different Android versions
    if (await Permission.storage.isRestricted) {
      permission = Permission.photos;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      if (rationaleMessage != null && context != null && context.mounted) {
        final shouldRequest = await _showPermissionRequestDialog(
          context,
          title: 'Storage Access Required',
          message: rationaleMessage,
        );
        if (!shouldRequest) return false;
      }
    }

    // Request permission directly
    final result = await permission.request();

    if (result.isPermanentlyDenied && context != null && context.mounted) {
      return await _showSettingsDialog(
        context,
        title: 'Storage Permission Required',
        message:
            'Storage access is permanently denied. Please enable it in app settings.',
      );
    }

    return result.isGranted;
  }

  // Download permission with direct request
  // Update the requestDownloadPermission method
  static Future<bool> requestDownloadPermission({
    BuildContext? context,
    String? rationaleMessage,
    bool isMedia = false,
  }) async {
    if (kIsWeb) return true;

    try {
      // Check which permissions are actually available
      Permission permission;

      // Try to determine the best permission for current Android version
      if (await Permission.storage.isGranted) {
        permission = Permission.storage;
      } else if (await Permission.manageExternalStorage.isGranted) {
        permission = Permission.manageExternalStorage;
      } else if (await Permission.photos.isGranted) {
        permission = Permission.photos;
      } else if (await Permission.mediaLibrary.isGranted) {
        permission = Permission.mediaLibrary;
      } else {
        // Start with storage permission
        permission = Permission.storage;
      }

      // Check status
      var status = await permission.status;
      print('📱 Permission check: ${permission.toString()} = $status');

      // If granted, return true
      if (status.isGranted) return true;

      // If limited or denied, show rationale
      if (status.isDenied || status.isLimited) {
        if (context != null && context.mounted) {
          final shouldRequest = await _showPermissionRequestDialog(
            context,
            title: 'Storage Access Required',
            message:
                rationaleMessage ??
                'Storage access is required to save QR codes to your gallery.',
          );
          if (!shouldRequest) return false;
        }
      }

      // Request the permission
      final result = await permission.request();
      print('📱 Permission request result: $result');

      // If permission is granted
      if (result.isGranted) return true;

      // If permanently denied, show settings option
      if (result.isPermanentlyDenied) {
        if (context != null && context.mounted) {
          return await _showSettingsDialog(
            context,
            title: 'Permission Required',
            message:
                'Storage access is required. Please enable it in app settings.',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error requesting permission: $e');

      // Fallback: Try a simple storage permission request
      try {
        final result = await Permission.storage.request();
        return result.isGranted;
      } catch (e2) {
        print('❌ Fallback permission request also failed: $e2');
        return false;
      }
    }
  }
  
  // Direct permission request dialog
  static Future<bool> _showPermissionRequestDialog(
    BuildContext? context, {
    required String title,
    required String? message,
    bool showCancel = true,
  }) async {
    if (context == null || !context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(
              message ?? 'This permission is required to continue.',
            ),
            actions: [
              if (showCancel)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Allow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Settings dialog (only for permanently denied permissions)
  static Future<bool> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Other permission methods remain the same but updated with new logic
  static Future<bool> requestBackgroundLocationPermission({
    required BuildContext context,
    String? rationaleMessage,
  }) async {
    final locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      final shouldRequest = await _showPermissionRequestDialog(
        context,
        title: 'Location Access Required',
        message:
            rationaleMessage ??
            'Location access is required for trip tracking.',
      );
      if (!shouldRequest) return false;

      final whenInUseResult = await Permission.locationWhenInUse.request();
      if (!whenInUseResult.isGranted) return false;
    }

    final status = await Permission.locationAlways.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionRequestDialog(
        context,
        title: 'Background Location Required',
        message:
            'Background location is required for tracking trips when the app is in background.',
      );
      if (!shouldRequest) return false;
    }

    final result = await Permission.locationAlways.request();

    if (result.isPermanentlyDenied) {
      return await _showSettingsDialog(
        context,
        title: 'Background Location Required',
        message:
            'Background location is permanently denied. Please enable it in app settings.',
      );
    }

    return result.isGranted;
  }

  // Phone permission
  static Future<bool> requestPhonePermission({
    BuildContext? context,
    String? rationaleMessage,
  }) async {
    final status = await Permission.phone.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionRequestDialog(
        context,
        title: 'Phone Access Required',
        message:
            rationaleMessage ?? 'Phone access is required for calling drivers.',
      );
      if (!shouldRequest) return false;
    }

    final result = await Permission.phone.request();

    if (result.isPermanentlyDenied && context != null && context.mounted) {
      return await _showSettingsDialog(
        context,
        title: 'Phone Permission Required',
        message:
            'Phone access is permanently denied. Please enable it in app settings.',
      );
    }

    return result.isGranted;
  }

  // Check permission status methods (unchanged)
  static Future<bool> isDownloadGranted({bool isMedia = false}) async {
    if (kIsWeb) return true;

    if (isMedia) {
      if (await Permission.manageExternalStorage.isRestricted) {
        return await Permission.storage.isGranted;
      }
      return await Permission.manageExternalStorage.isGranted;
    } else {
      if (await Permission.storage.isRestricted) {
        return await Permission.photos.isGranted;
      }
      return await Permission.storage.isGranted;
    }
  }

  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> isStorageGranted() async {
    if (await Permission.storage.isRestricted) {
      return await Permission.photos.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  static Future<bool> isLocationAlwaysGranted() async {
    return await Permission.locationAlways.isGranted;
  }

  static Future<bool> isPhoneGranted() async {
    return await Permission.phone.isGranted;
  }
}
