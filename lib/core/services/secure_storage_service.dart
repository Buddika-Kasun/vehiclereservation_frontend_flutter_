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

  // Get tokens
  Future<String?> get accessToken async =>
      await _storage.read(key: 'accessToken');
  Future<String?> get refreshToken async =>
      await _storage.read(key: 'refreshToken');

  // Clear tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }
}

