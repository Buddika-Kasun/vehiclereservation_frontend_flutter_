import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/firebase_notification_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';

class AuthManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void logout({bool fromError = false}) async {
    try {
      // Clear FCM token from backend (optional, but good to have)
      try {
        await FirebaseNotificationService().onUserLogout();
      } catch (e) {
        print('Error clearing FCM token: $e');
      }

      // Clear storage
      await StorageService.clearUserData();
      await SecureStorageService().clearTokens();

      // Reset API service session flag
      ApiService.resetSession();

      // Navigate to login screen
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }

      print('User logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  static Future<bool> checkAuthStatus() async {
    try {
      final hasValidSession = await StorageService.hasValidSession;
      if (!hasValidSession) {
        logout();
        return false;
      }
      return true;
    } catch (e) {
      print('Error checking auth status: $e');
      logout();
      return false;
    }
  }

  // Optional: Handle session timeout
  static void handleSessionTimeout() {
    // You can show a dialog before logout
    if (navigatorKey.currentState != null) {
      showDialog(
        context: navigatorKey.currentState!.overlay!.context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.4),
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon section
                Container(
                  padding: EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.error.withOpacity(0.2),
                        Theme.of(context).colorScheme.error.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Session Expired',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your session has expired',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'For security reasons, please log in again to continue using the app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                logout();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Login Again',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      logout();
    }
  }

}
