// lib/services/secure_storage_service.dart - ADD INIT METHOD
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  // Initialize if needed
  Future<void> init() async {
    // Any initialization logic can go here
  }

  // Save tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  // Save FCM token securely
  Future<void> saveFcmToken(String fcmToken) async {
    await _storage.write(key: 'fcmToken', value: fcmToken);
  }

  // Get tokens
  Future<String?> get accessToken async =>
      await _storage.read(key: 'accessToken');
  Future<String?> get refreshToken async =>
      await _storage.read(key: 'refreshToken');
  Future<String?> get fcmToken async => 
      await _storage.read(key: 'fcmToken');

  Future<bool> isUserLoggedIn() async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  // Clear tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }
}

