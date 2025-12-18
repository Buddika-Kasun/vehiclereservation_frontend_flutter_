// lib/services/storage_service.dart - FIXED
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/secure_storage_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static User? get userData {
    final data = _prefs?.getString('userData');
    if (data != null) {
      try {
        final map = json.decode(data) as Map<String, dynamic>;
        return User.fromJson(map);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> saveUserData({
    required User userData,
    required Map<String, dynamic> originalJson,
  }) async {
    // Save the original JSON for compatibility
    await _prefs?.setString('userData', json.encode(originalJson));
    await _prefs?.setBool('isLoggedIn', true);
  }

  // Fix: Return UserRole instead of String
  static UserRole get currentRole {
    final roleString = _prefs?.getString('currentRole') ?? 'USER';
    try {
      return UserRole.fromString(roleString);
    } catch (e) {
      return UserRole.employee; // Default fallback
    }
  }

  // Add method to save current role
  static Future<void> saveCurrentRole(UserRole role) async {
    await _prefs?.setString('currentRole', role.value);
  }

  static bool get isLoggedIn => _prefs?.getBool('isLoggedIn') ?? false;

  // Clear data on logout
  static Future<void> clearUserData() async {
    await _prefs?.remove('userData');
    await _prefs?.remove('currentRole');
    await _prefs?.remove('isLoggedIn');
  }

  // Check if access token is expired
  static Future<bool> get isAccessTokenExpired async {
    final token = await SecureStorageService().accessToken;
    if (token == null) return true;

    try {
      // JWT tokens have 3 parts separated by dots: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Decode the payload (middle part)
      final payload = parts[1];
      // Add padding if needed
      var padded = payload;
      while (padded.length % 4 != 0) {
        padded += '=';
      }

      // Decode from base64
      final decoded = utf8.decode(base64.decode(padded));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      // Get expiration time (exp is in seconds since epoch)
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;

      // Convert to milliseconds and check if expired
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationTime);
    } catch (e) {
      return true; // If we can't decode, assume expired
    }
  }

  // Check if refresh token is expired (if it has expiration)
  static Future<bool> get isRefreshTokenExpired async {
    final token = await SecureStorageService().refreshToken;
    if (token == null) return true;

    // Refresh tokens might not be JWT, so you might need different logic
    // For now, we'll assume it's valid if it exists
    return false;
  }

  // Check if user has valid session
  static Future<bool> get hasValidSession async {
    return isLoggedIn && !(await isAccessTokenExpired);
  }
}

