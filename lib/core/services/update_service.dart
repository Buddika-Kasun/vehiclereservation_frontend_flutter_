// import 'dart:convert';
// import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  // ==================== PLAY STORE UPDATE METHODS ====================

  /// Check if update is available on Play Store
  Future<UpdateCheckResponse> checkPlayStoreUpdate() async {
    try {
      print("Start check play store update");
      // Check if Play Store update is available
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Update is available on Play Store
        print('📱 Play Store update available: ${updateInfo.updatePriority}');

        // Get package info for version
        final packageInfo = await PackageInfo.fromPlatform();

        // Get update priority (1 = high, 0 = low)
        final isMandatory = updateInfo.updatePriority >= 1;

        return UpdateCheckResponse(
          updateAvailable: true,
          updateType: 'store_redirect',
          isMandatory: isMandatory,
          data: AppUpdate(
            id: 'play_store_update',
            version: 'Latest',
            buildNumber: packageInfo.buildNumber,
            platform: 'android',
            updateTitle: 'Update Available',
            updateDescription:
                'A new version is available on the Play Store. Please update to continue using the app.',
            fileSize: 0.0,
            isMandatory: isMandatory,
            isSilent: false,
            isActive: true,
            redirectToStore: true,
            createdAt: DateTime.now(),
            releaseNotes: 'A new version is available on the Play Store.',
          ),
        );
      }

      return UpdateCheckResponse(
        updateAvailable: false,
        updateType: null,
        data: null,
        isMandatory: false,
      );
    } catch (e) {
      print('❌ Play Store update check failed: $e');
      return UpdateCheckResponse(
        updateAvailable: false,
        updateType: null,
        data: null,
        isMandatory: false,
      );
    }
  }

  /// Start immediate Play Store update (for critical updates)
  Future<void> startPlayStoreUpdateImmediate() async {
    try {
      // Start the immediate update flow
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      print('❌ Failed to start immediate Play Store update: $e');
      // Fallback to flexible update
      await startPlayStoreUpdateFlexible();
    }
  }

  /// Start flexible Play Store update (download in background)
  Future<void> startPlayStoreUpdateFlexible() async {
    try {
      // Start flexible update
      await InAppUpdate.startFlexibleUpdate();

      // Optionally, check if update is complete
      // You can listen to update progress
    } catch (e) {
      print('❌ Failed to start flexible Play Store update: $e');
    }
  }

  /// Complete flexible update (after download is complete)
  Future<void> completePlayStoreUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      print('❌ Failed to complete flexible update: $e');
    }
  }

  /// Redirect to Play Store app page
  Future<void> redirectToPlayStore() async {
    try {
      // Get package name
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      // Play Store URL
      final playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';

      // Try to open Play Store app first
      final playStoreAppUrl = 'market://details?id=$packageName';

      if (await canLaunchUrl(Uri.parse(playStoreAppUrl))) {
        await launchUrl(Uri.parse(playStoreAppUrl));
      } else if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(Uri.parse(playStoreUrl));
      } else {
        throw Exception('Could not open Play Store');
      }
    } catch (e) {
      print('❌ Failed to open Play Store: $e');
      rethrow;
    }
  }

  /// Show update required dialog (for mandatory updates)
  Future<void> showUpdateRequiredDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
          'A mandatory update is available. Please update the app from the Play Store to continue.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await redirectToPlayStore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9C80E),
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Play Store'),
          ),
        ],
      ),
    );
  }

  /// Show update dialog with option to skip
  Future<void> showUpdateDialog(
    BuildContext context, {
    required AppUpdate update,
    required VoidCallback onUpdate,
    VoidCallback? onLater,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: !update.isMandatory,
      builder: (context) => AlertDialog(
        title: Text(update.updateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   'Version ${update.version} is available on the Play Store.',
            //   style: const TextStyle(fontSize: 16),
            // ),
            // const SizedBox(height: 12),
            if (update.releaseNotes != null &&
                update.releaseNotes!.isNotEmpty) ...[
              // const Text(
              //   'What\'s new:',
              //   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 8),
              Text(
                update.releaseNotes!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            if (update.isMandatory)
              const Text(
                '⚠️ This update is mandatory. Please update to continue using the app.',
                style: TextStyle(fontSize: 14, color: Colors.orange),
              ),
          ],
        ),
        actions: [
          if (!update.isMandatory && onLater != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLater();
              },
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9C80E),
              foregroundColor: Colors.black,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  // ==================== BACKEND UPDATE METHODS (DISABLED) ====================

  /*
  /// Check for update from backend (custom APK updates) - DISABLED
  Future<UpdateCheckResponse> checkForUpdate() async {
    // This method is disabled - only Play Store updates are used
    return UpdateCheckResponse(updateAvailable: false);
  }

  /// Download and install update from backend - DISABLED
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
    // This method is disabled - only Play Store updates are used
    onError('Backend updates are disabled. Please use Play Store updates.');
  }
  */

  // ==================== CLEANUP METHODS ====================

  /// Clean up old update files
  Future<void> cleanupOldUpdates() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final updatesDir = Directory('${appDocDir.path}/updates');

      if (await updatesDir.exists()) {
        final files = await updatesDir.list().toList();
        final now = DateTime.now();

        for (var file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = now.difference(stat.modified);

            // Delete files older than 7 days
            if (age.inDays > 7) {
              await file.delete();
              print('🗑️ Deleted old update file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed to cleanup old updates: $e');
    }
  }
}
