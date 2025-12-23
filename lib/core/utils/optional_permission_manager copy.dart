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
    if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (context != null && context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: 'Camera Permission Required',
          message:
              'Camera access is required for scanning QR codes and uploading documents. Please enable it in app settings.',
        );
      }
      return false;
    }

    // Show rationale if needed
    if (status.isDenied &&
        rationaleMessage != null &&
        context != null &&
        context.mounted) {
      await _showRationaleDialog(context, rationaleMessage);
    }

    // Request permission
    final result = await Permission.camera.request();
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
    if (status.isPermanentlyDenied) {
      if (context != null && context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: 'Storage Permission Required',
          message:
              'Storage access is required for uploading documents and saving files. Please enable it in app settings.',
        );
      }
      return false;
    }

    if (status.isDenied &&
        rationaleMessage != null &&
        context != null &&
        context.mounted) {
      await _showRationaleDialog(context, rationaleMessage);
    }

    final result = await permission.request();
    return result.isGranted;
  }

  // Location Always (for background tracking)
  static Future<bool> requestBackgroundLocationPermission({
    required BuildContext context,
    String? rationaleMessage,
  }) async {
    // First check if location when in use is granted
    final locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      // Request location when in use first
      final whenInUseResult = await Permission.locationWhenInUse.request();
      if (!whenInUseResult.isGranted) return false;
    }

    // Now request background location
    final status = await Permission.locationAlways.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: 'Background Location Required',
          message:
              'Background location is required for tracking trips when the app is in background. Please enable it in app settings.',
        );
      }
      return false;
    }

    if (status.isDenied && rationaleMessage != null && context.mounted) {
      await _showRationaleDialog(context, rationaleMessage);
    }

    final result = await Permission.locationAlways.request();
    return result.isGranted;
  }

  // Phone permission (for calling driver)
  static Future<bool> requestPhonePermission({
    BuildContext? context,
    String? rationaleMessage,
  }) async {
    final status = await Permission.phone.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (context != null && context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: 'Phone Permission Required',
          message:
              'Phone access is required for calling drivers. Please enable it in app settings.',
        );
      }
      return false;
    }

    if (status.isDenied &&
        rationaleMessage != null &&
        context != null &&
        context.mounted) {
      await _showRationaleDialog(context, rationaleMessage);
    }

    final result = await Permission.phone.request();
    return result.isGranted;
  }

  // Helper methods
  static Future<void> _showRationaleDialog(
    BuildContext context,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Download/Storage permissions
  static Future<bool> requestDownloadPermission({
    BuildContext? context,
    String? rationaleMessage,
    bool isMedia = false,
  }) async {
    if (kIsWeb) return true; // Web doesn't need storage permission

    Permission permission;

    // Handle different Android versions and file types
    if (isMedia) {
      // For media files (images, videos, audio)
      if (await Permission.manageExternalStorage.isRestricted) {
        permission = Permission.storage;
      } else {
        permission = Permission.manageExternalStorage;
      }
    } else {
      // For documents (PDF, Excel, etc.)
      if (await Permission.storage.isRestricted) {
        permission = Permission.photos; // Fallback for iOS
      } else {
        permission = Permission.storage;
      }
    }

    final status = await permission.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (context != null && context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: 'Storage Permission Required',
          message:
              'Storage access is required to download files. Please enable it in app settings.',
        );
      }
      return false;
    }

    if (status.isDenied &&
        rationaleMessage != null &&
        context != null &&
        context.mounted) {
      await _showRationaleDialog(context, rationaleMessage);
    }

    final result = await permission.request();
    return result.isGranted;
  }

  // Check download permission status
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

  // Check if permission is granted
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
