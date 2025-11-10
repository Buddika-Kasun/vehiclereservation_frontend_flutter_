import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';

class AuthInterceptor {
  static Future<Map<String, dynamic>> callApi(
    String endpoint, {
    String method = 'GET',
    dynamic body,
  }) async {
    try {
      return await ApiService.authenticatedApiCall(
        endpoint,
        method: method,
        body: body,
      );
    } catch (e) {
      // If API call fails due to auth, redirect to login
      if (e.toString().contains('401') || 
          e.toString().contains('token') || 
          e.toString().contains('authentication')) {
        
        // Clear stored data
        await StorageService.clearUserData();
        
        // You might want to navigate to login screen here
        // This would require a global navigator key
      }
      rethrow;
    }
  }
}