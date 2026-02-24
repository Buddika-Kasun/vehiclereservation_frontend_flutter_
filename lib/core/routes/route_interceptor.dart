// lib/core/routes/route_interceptor.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/routes/app_routes.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';

class RouteInterceptor {
  // Handle initial route based on auth state
  static Future<String> getInitialRoute() async {
    // Check if user is logged in
    final hasSession = await StorageService.hasValidSession;
    if (!hasSession) {
      return AppRoutes.welcome;
    }

    // Verify user data exists
    final user = StorageService.userData;
    final token = await SecureStorageService().accessToken;
    if (user == null || token == null) {
      return AppRoutes.login;
    }

    return AppRoutes.home;
  }

  // Parse URL parameters
  static Map<String, dynamic> parseUrlParameters(Uri uri) {
    final params = <String, dynamic>{};

    // Extract query parameters
    uri.queryParameters.forEach((key, value) {
      params[key] = value;
    });

    // Extract path segments for dynamic routes
    final path = uri.path;
    if (path.startsWith('/trip-details/')) {
      final segments = path.split('/');
      if (segments.length >= 3) {
        params['tripId'] = segments[2];
      }
    }

    return params;
  }

  // Check if URL requires authentication
  static bool requiresAuth(String route) {
    final publicRoutes = [
      AppRoutes.welcome,
      AppRoutes.login,
      AppRoutes.adminLogin,
    ];

    return !publicRoutes.contains(route);
  }
}
