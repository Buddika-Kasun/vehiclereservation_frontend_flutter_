import 'dart:io';
import 'dart:convert';
import 'dart:html' as html; // For web operations
import 'dart:js' as js; 
import 'package:flutter/foundation.dart'; // Add this import
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';

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

      if (Platform.isAndroid) {
        platform = 'android';
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        platform = 'ios';
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
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

  Future<void> downloadUpdate({
    required String downloadUrl,
    required String fileName,
    required Function(double) onProgress,
    required Function(String) onComplete,
    required Function(String) onError,
  }) async {
    try {
      final response = await _dio.get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200) {
        // For web, trigger download via blob
        if (kIsWeb) {
          final bytes = response.data as List<int>;

          // Method 1: Using dart:html with proper prefix
          final blob = html.Blob([Uint8List.fromList(bytes)]);
          final url = html.Url.createObjectUrlFromBlob(blob);

          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();

          html.Url.revokeObjectUrl(url);
          onComplete('Download complete');
        } else {
          // For mobile, save file (you'll need platform-specific code here)
          onComplete('File downloaded');
        }
      } else {
        onError('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      onError('Download failed: $e');
    }
  }

}
