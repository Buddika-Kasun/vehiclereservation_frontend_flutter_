import 'dart:math';

class UpdateCheckResponse {
  final bool updateAvailable;
  final String? updateType;
  final bool? isMandatory;
  final AppUpdate? data;
  final String? message;

  UpdateCheckResponse({
    required this.updateAvailable,
    this.updateType,
    this.isMandatory,
    this.data,
    this.message,
  });

  factory UpdateCheckResponse.fromJson(Map<String, dynamic> json) {
    return UpdateCheckResponse(
      updateAvailable: json['updateAvailable'] ?? false,
      updateType: json['updateType'],
      isMandatory: json['isMandatory'] ?? false,
      data: json['data'] != null ? AppUpdate.fromJson(json['data']) : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updateAvailable': updateAvailable,
      'updateType': updateType,
      'data': data?.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'UpdateCheckResponse{updateAvailable: $updateAvailable, updateType: $updateType, data: $data, message: $message}';
  }
}

class AppUpdate {
  final String id;
  final String version;
  final String buildNumber;
  final String platform;
  final String updateTitle;
  final String updateDescription;
  final String? downloadUrl;
  final String? fileName;
  final String? filePath;
  final String? originalFileName;
  final double fileSize;
  final bool isMandatory;
  final bool isSilent;
  final bool isActive;
  final bool redirectToStore;
  final String? minSupportedVersion;
  final String? releaseNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUpdate({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.updateTitle,
    required this.updateDescription,
    this.downloadUrl,
    this.fileName,
    this.filePath,
    this.originalFileName,
    required this.fileSize,
    required this.isMandatory,
    required this.isSilent,
    required this.isActive,
    required this.redirectToStore,
    this.minSupportedVersion,
    this.releaseNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      id: json['id'] ?? '',
      version: json['version'] ?? '',
      buildNumber: json['buildNumber'] ?? '',
      platform: json['platform'] ?? 'both',
      updateTitle: json['updateTitle'] ?? '',
      updateDescription: json['updateDescription'] ?? '',
      downloadUrl: json['downloadUrl'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      originalFileName: json['originalFileName'],
      fileSize: json['fileSize']?.toDouble() ?? 0.0,
      isMandatory: json['isMandatory'] ?? false,
      isSilent: json['isSilent'] ?? false,
      isActive: json['isActive'] ?? true,
      redirectToStore: json['redirectToStore'] ?? false,
      minSupportedVersion: json['minSupportedVersion'],
      releaseNotes: json['releaseNotes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'buildNumber': buildNumber,
      'platform': platform,
      'updateTitle': updateTitle,
      'updateDescription': updateDescription,
      'downloadUrl': downloadUrl,
      'fileName': fileName,
      'filePath': filePath,
      'originalFileName': originalFileName,
      'fileSize': fileSize,
      'isMandatory': isMandatory,
      'isSilent': isSilent,
      'isActive': isActive,
      'redirectToStore': redirectToStore,
      'minSupportedVersion': minSupportedVersion,
      'releaseNotes': releaseNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to get display platform name
  String get platformDisplayName {
    switch (platform.toLowerCase()) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'web':
        return 'Web';
      case 'both':
        return 'Android & iOS';
      default:
        return platform;
    }
  }

  // Helper method to check if this update is for current platform
  bool isForPlatform(String currentPlatform) {
    if (platform == 'both') {
      return currentPlatform == 'android' || currentPlatform == 'ios';
    }
    return platform == currentPlatform;
  }

  // Helper method to get file extension
  String? get fileExtension {
    if (fileName == null) return null;
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last : null;
  }

  // Helper method to check if file is APK
  bool get isApkFile {
    return fileExtension?.toLowerCase() == 'apk';
  }

  // Helper method to check if file is IPA
  bool get isIpaFile {
    return fileExtension?.toLowerCase() == 'ipa';
  }

  @override
  String toString() {
    return 'AppUpdate{id: $id, version: $version, buildNumber: $buildNumber, platform: $platform, title: $updateTitle}';
  }
}

// Request model for checking updates
class CheckUpdateRequest {
  final String currentVersion;
  final String currentBuild;
  final String platform;
  final String? deviceId;
  final String? deviceModel;
  final String? osVersion;

  CheckUpdateRequest({
    required this.currentVersion,
    required this.currentBuild,
    required this.platform,
    this.deviceId,
    this.deviceModel,
    this.osVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentVersion': currentVersion,
      'currentBuild': currentBuild,
      'platform': platform,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
    };
  }

  Map<String, dynamic> toQueryParams() {
    final params = {
      'currentVersion': currentVersion,
      'currentBuild': currentBuild,
      'platform': platform,
    };

    if (deviceId != null) params['deviceId'] = deviceId.toString();
    if (deviceModel != null) params['deviceModel'] = deviceModel.toString();
    if (osVersion != null) params['osVersion'] = osVersion.toString();

    return params;
  }
}

// Model for upload progress
class UploadProgress {
  final int sent;
  final int total;
  final double percentage;

  UploadProgress({required this.sent, required this.total})
    : percentage = total > 0 ? sent / total : 0.0;

  String get progressText {
    final sentMB = sent / (1024 * 1024);
    final totalMB = total / (1024 * 1024);
    return '${sentMB.toStringAsFixed(2)} MB / ${totalMB.toStringAsFixed(2)} MB';
  }

  String get percentageText {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }
}

// Model for download progress
class DownloadProgress {
  final int received;
  final int total;
  final double percentage;
  final String fileName;

  DownloadProgress({
    required this.received,
    required this.total,
    required this.fileName,
  }) : percentage = total > 0 ? received / total : 0.0;

  String get progressText {
    final receivedMB = received / (1024 * 1024);
    final totalMB = total / (1024 * 1024);
    return '${receivedMB.toStringAsFixed(2)} MB / ${totalMB.toStringAsFixed(2)} MB';
  }

  String get percentageText {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }
}

// Model for update statistics
class UpdateStats {
  final int totalUpdates;
  final int androidUpdates;
  final int iosUpdates;
  final int mandatoryUpdates;
  final int silentUpdates;
  final double averageFileSize;

  UpdateStats({
    required this.totalUpdates,
    required this.androidUpdates,
    required this.iosUpdates,
    required this.mandatoryUpdates,
    required this.silentUpdates,
    required this.averageFileSize,
  });

  factory UpdateStats.fromJson(Map<String, dynamic> json) {
    return UpdateStats(
      totalUpdates: json['totalUpdates'] ?? 0,
      androidUpdates: json['androidUpdates'] ?? 0,
      iosUpdates: json['iosUpdates'] ?? 0,
      mandatoryUpdates: json['mandatoryUpdates'] ?? 0,
      silentUpdates: json['silentUpdates'] ?? 0,
      averageFileSize: json['averageFileSize']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUpdates': totalUpdates,
      'androidUpdates': androidUpdates,
      'iosUpdates': iosUpdates,
      'mandatoryUpdates': mandatoryUpdates,
      'silentUpdates': silentUpdates,
      'averageFileSize': averageFileSize,
    };
  }
}

// Model for update creation request
class CreateUpdateRequest {
  final String version;
  final String buildNumber;
  final String platform;
  final String updateTitle;
  final String updateDescription;
  final bool isMandatory;
  final bool isSilent;
  final bool redirectToStore;
  final String? releaseNotes;
  final String? minSupportedVersion;

  CreateUpdateRequest({
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.updateTitle,
    required this.updateDescription,
    this.isMandatory = false,
    this.isSilent = false,
    this.redirectToStore = false,
    this.releaseNotes,
    this.minSupportedVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'platform': platform,
      'updateTitle': updateTitle,
      'updateDescription': updateDescription,
      'isMandatory': isMandatory,
      'isSilent': isSilent,
      'redirectToStore': redirectToStore,
      'releaseNotes': releaseNotes,
      'minSupportedVersion': minSupportedVersion,
    };
  }

  @override
  String toString() {
    return 'CreateUpdateRequest{version: $version, platform: $platform, title: $updateTitle}';
  }
}

// Model for update response (without file)
class UpdateResponse {
  final String id;
  final String version;
  final String buildNumber;
  final String platform;
  final String updateTitle;
  final bool isMandatory;
  final bool isActive;
  final DateTime createdAt;

  UpdateResponse({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.updateTitle,
    required this.isMandatory,
    required this.isActive,
    required this.createdAt,
  });

  factory UpdateResponse.fromJson(Map<String, dynamic> json) {
    return UpdateResponse(
      id: json['id'],
      version: json['version'],
      buildNumber: json['buildNumber'],
      platform: json['platform'],
      updateTitle: json['updateTitle'],
      isMandatory: json['isMandatory'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// Model for batch update operations
class BatchUpdateOperation {
  final List<String> updateIds;
  final bool setActive;
  final bool? setMandatory;

  BatchUpdateOperation({
    required this.updateIds,
    required this.setActive,
    this.setMandatory,
  });

  Map<String, dynamic> toJson() {
    return {
      'updateIds': updateIds,
      'setActive': setActive,
      'setMandatory': setMandatory,
    };
  }
}

// Model for version comparison
class VersionInfo {
  final String version;
  final String buildNumber;

  VersionInfo({required this.version, required this.buildNumber});

  // Compare two versions
  static bool isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < max(newParts.length, currentParts.length); i++) {
      // FIXED: math.max to max
      final newPart = i < newParts.length ? newParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;

      if (newPart > currentPart) return true;
      if (newPart < currentPart) return false;
    }

    return false;
  }

  // Compare versions including build number
  static bool isNewerBuild(VersionInfo newVersion, VersionInfo currentVersion) {
    // First compare version numbers
    if (isNewerVersion(newVersion.version, currentVersion.version)) {
      return true;
    }

    // If versions are equal, compare build numbers
    if (newVersion.version == currentVersion.version) {
      try {
        final newBuild = int.parse(newVersion.buildNumber);
        final currentBuild = int.parse(currentVersion.buildNumber);
        return newBuild > currentBuild;
      } catch (e) {
        // If build numbers aren't numeric, compare as strings
        return newVersion.buildNumber.compareTo(currentVersion.buildNumber) > 0;
      }
    }

    return false;
  }
}

// Model for update notification
class UpdateNotification {
  final String id;
  final String title;
  final String message;
  final String version;
  final bool isMandatory;
  final DateTime timestamp;

  UpdateNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.version,
    required this.isMandatory,
    required this.timestamp,
  });

  factory UpdateNotification.fromJson(Map<String, dynamic> json) {
    return UpdateNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      version: json['version'],
      isMandatory: json['isMandatory'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Enum for update types
enum UpdateType { silent, userConfirmation, storeRedirect, none }

extension UpdateTypeExtension on UpdateType {
  String get displayName {
    switch (this) {
      case UpdateType.silent:
        return 'Silent Update';
      case UpdateType.userConfirmation:
        return 'User Confirmation';
      case UpdateType.storeRedirect:
        return 'Store Redirect';
      case UpdateType.none:
        return 'No Update';
    }
  }

  String? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'silent':
        return 'silent';
      case 'user_confirmation':
      case 'userconfirmation':
        return 'user_confirmation';
      case 'store_redirect':
      case 'storeredirect':
        return 'store_redirect';
      default:
        return null;
    }
  }
}
