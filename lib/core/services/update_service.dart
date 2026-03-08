import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<UpdateCheckResponse> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String platform = 'web';
      String? deviceId;
      String? deviceModel;
      String? osVersion;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        platform = 'android';
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        osVersion = androidInfo.version.release;
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
      } else if (kIsWeb) {
        platform = 'web';
      }

      final response = await _dio.get(
        '/updates/check',
        queryParameters: {
          'currentVersion': packageInfo.version,
          'currentBuild': packageInfo.buildNumber,
          'platform': platform,
          'deviceId': deviceId,
          'deviceModel': deviceModel,
          'osVersion': osVersion,
        },
      );

      if (response.statusCode == 200) {
        return UpdateCheckResponse.fromJson(response.data);
      }

      return UpdateCheckResponse(updateAvailable: false);
    } catch (e) {
      print('Error checking for update: $e');
      return UpdateCheckResponse(updateAvailable: false);
    }
  }

  Future<void> downloadAndInstallUpdate({
    required String downloadUrl,
    required String fileName,
    required BuildContext context,
    required Function(double) onDownloadProgress,
    required Function(String) onDownloadComplete,
    required Function(String) onInstallStart,
    required Function(String) onInstallComplete,
    required Function(String) onError,
  }) async {
    try {
      print('🚀 Starting download and installation process');

      // Validate URL
      if (downloadUrl.isEmpty || !downloadUrl.startsWith('http')) {
        onError('Invalid download URL: $downloadUrl');
        return;
      }

      if (kIsWeb) {
        _downloadFileWeb(downloadUrl, fileName);
        onDownloadComplete('Download started');
      } else {
        // Request permissions first
        final permissionsGranted = await _requestUpdatePermissions(context);
        if (!permissionsGranted) {
          onError('Required permissions were not granted');
          return;
        }

        // Download file
        final filePath = await _downloadApkFile(
          downloadUrl: downloadUrl,
          fileName: fileName,
          onProgress: onDownloadProgress,
        );

        // Install APK
        onInstallStart('Preparing installation...');
        await _installApk(filePath, context);

        onInstallComplete('Installation started successfully!');
      }
    } catch (e) {
      print('❌ Error: $e');
      onError(_getUserFriendlyError(e));
    }
  }

  Future<bool> _requestUpdatePermissions(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      // Get Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      print('📱 Android SDK: $sdkVersion');

      // 1. Request Storage Permission
      final storageGranted = await _requestStoragePermission(
        context,
        sdkVersion,
      );
      if (!storageGranted) {
        return false;
      }

      // 2. Request Install Permission (Android 8.0+)
      if (sdkVersion >= 26) {
        final installGranted = await _requestInstallPermission(context);
        if (!installGranted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Permission error: $e');
      return false;
    }
  }

  Future<bool> _requestStoragePermission(
    BuildContext context,
    int sdkVersion,
  ) async {
    try {
      print('🔐 Requesting storage permission...');

      // Check Android version and use appropriate permission
      Permission permissionToRequest;

      if (sdkVersion >= 33) {
        // Android 13+ - Use media permissions
        permissionToRequest = Permission.manageExternalStorage;
      } else if (sdkVersion >= 30) {
        // Android 11-12 - Use manage external storage
        permissionToRequest = Permission.manageExternalStorage;
      } else {
        // Android < 11 - Use traditional storage
        permissionToRequest = Permission.storage;
      }

      // Check current status
      var status = await permissionToRequest.status;
      print('📱 Storage permission status: $status');

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied || status.isLimited) {
        // Show explanation dialog
        final shouldRequest = await _showStoragePermissionDialog(
          context,
          sdkVersion,
        );
        if (!shouldRequest) {
          return false;
        }

        // Request permission
        status = await permissionToRequest.request();

        if (status.isGranted) {
          return true;
        }
      }

      // If permanently denied or still not granted
      if (status.isPermanentlyDenied) {
        final shouldOpenSettings = await _showPermissionSettingsDialog(
          context,
          title: 'Storage Permission Required',
          message:
              'Storage access is required to save update files. '
              'Please enable it in app settings.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
          // Wait and check again
          await Future.delayed(const Duration(seconds: 1));
          status = await permissionToRequest.status;
          return status.isGranted;
        }
      }

      return false;
    } catch (e) {
      print('❌ Storage permission error: $e');
      return false;
    }
  }

  Future<bool> _requestInstallPermission(BuildContext context) async {
    try {
      print('🔐 Requesting install permission...');

      var status = await Permission.requestInstallPackages.status;
      print('📱 Install permission status: $status');

      if (status.isGranted) {
        return true;
      }

      // Request permission
      status = await Permission.requestInstallPackages.request();

      if (status.isGranted) {
        return true;
      }

      // Show explanation dialog
      final shouldOpenSettings = await _showInstallPermissionDialog(context);
      if (shouldOpenSettings) {
        await openAppSettings();
        await Future.delayed(const Duration(seconds: 1));
        status = await Permission.requestInstallPackages.status;
        return status.isGranted;
      }

      return false;
    } catch (e) {
      print('❌ Install permission error: $e');
      return false;
    }
  }

  Future<bool> _showStoragePermissionDialog(
    BuildContext context,
    int sdkVersion,
  ) async {
    String message;

    if (sdkVersion >= 33) {
      message =
          'To save update files, you need to allow access to files and media.';
    } else if (sdkVersion >= 30) {
      message =
          'To save update files, you need to allow access to manage all files.';
    } else {
      message =
          'Storage permission is required to save update files to your device.';
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Storage Access Required'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showPermissionSettingsDialog(
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showInstallPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Install Permission Required'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To install updates, you need to allow this app to install unknown apps.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'How to enable:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. Tap "Open Settings" below'),
                Text('2. Find "Install unknown apps"'),
                Text('3. Enable "Allow from this source"'),
                Text('4. Return to this app'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String> _downloadApkFile({
    required String downloadUrl,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    try {
      print('📥 Starting download...');

      final response = await _dio.get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      // Save file to device
      final bytes = response.data as Uint8List;
      final filePath = await _saveApkToDevice(bytes, fileName);

      print('✅ Download complete. File saved to: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Download error: $e');
      rethrow;
    }
  }

  Future<String> _saveApkToDevice(Uint8List bytes, String fileName) async {
    try {
      // Try app-specific directory first (no permission needed)
      final appDocDir = await getApplicationDocumentsDirectory();
      final updatesDir = Directory('${appDocDir.path}/updates');

      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = fileName.replaceAll('.apk', '_$timestamp.apk');
      final filePath = '${updatesDir.path}/$safeFileName';
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      print('✅ File saved to app directory: $filePath');
      return filePath;
    } catch (e) {
      print('⚠️ Failed to save to app directory: $e');

      // Fallback to external storage if app directory fails
      try {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception('Cannot access external storage');
        }

        final downloadsDir = Directory(
          '${directory.path}/Download/PCW_RIDE_Updates',
        );

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeFileName = fileName.replaceAll('.apk', '_$timestamp.apk');
        final filePath = '${downloadsDir.path}/$safeFileName';
        final file = File(filePath);

        await file.writeAsBytes(bytes);

        print('✅ File saved to external storage: $filePath');
        return filePath;
      } catch (e2) {
        print('❌ Failed to save to external storage: $e2');
        throw Exception('Failed to save file: $e2');
      }
    }
  }

  Future<void> _installApk(String filePath, BuildContext context) async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        throw Exception('APK installation only supported on Android');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('APK file not found: $filePath');
      }

      print('🔧 Opening APK installer for: $filePath');
      final result = await OpenFile.open(filePath);

      print('📱 OpenFile result: ${result.type} - ${result.message}');

      if (result.type != ResultType.done) {
        throw Exception('Failed to open installer: ${result.message}');
      }

      // Show success message
      _showInstallationStartedDialog(context);
    } catch (e) {
      print('❌ Installation error: $e');
      rethrow;
    }
  }

  void _showInstallationStartedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Installation Started'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.system_update, size: 50, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'The system installer will now open.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please follow the on-screen instructions to complete the installation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getUserFriendlyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission') || errorStr.contains('access')) {
      return 'Permission denied. Please grant the required permissions and try again.';
    } else if (errorStr.contains('storage')) {
      return 'Storage access is required. Please enable storage permission in app settings.';
    } else if (errorStr.contains('install')) {
      return 'Install permission required. Please enable "Install unknown apps" for this app.';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else {
      return 'Update failed: $error';
    }
  }

  void _downloadFileWeb(String downloadUrl, String fileName) {
    if (kIsWeb) {
      print('🌐 Web download: $downloadUrl');
    }
  }
}
