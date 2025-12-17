import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/auth_screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';

class AuthManager {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static void logout() async {
    await StorageService.clearUserData();
    await SecureStorageService().clearTokens();
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
  
  static void checkAuthStatus() async {
    if (!(await StorageService.hasValidSession)) {
      logout();
    }
  }
}