// services/authority_service.dart
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import '../models/user_model.dart';

class AuthorityService {
  static Map<String, dynamic>? _cachedApprovalConfig;
  static DateTime? _lastConfigFetch;
  static const Duration configCacheDuration = Duration(minutes: 5);

  // Check if user has user creation authority
  static bool hasUserCreationAuthority(User user) {
    if (user.role == UserRole.hr || 
        user.role == UserRole.admin || 
        user.role == UserRole.sysadmin) {
      return true;
    }
    
    if (user.role == UserRole.employee) {
      return user.authenticationLevel == 3;
    }
    
    return false;
  }

  // Synchronous method for UI use
  static bool hasTripApprovalAuthority(User user) {
    // If user is sysadmin, they have authority
    if (user.role == UserRole.sysadmin) {
      return true;
    }

    // Check cached config
    if (_cachedApprovalConfig != null && 
        _lastConfigFetch != null && 
        DateTime.now().difference(_lastConfigFetch!) < configCacheDuration) {
      
      final secondaryUserId = _cachedApprovalConfig!['secondaryUserId'];
      final safetyUserId = _cachedApprovalConfig!['safetyUserId'];
      final hodId = _cachedApprovalConfig!['hodId'];

      if (secondaryUserId != null && user.id == secondaryUserId) return true;
      if (safetyUserId != null && user.id == safetyUserId) return true;
      if (hodId != null && user.id == hodId) return true;
    }

    // Fallback to role-based check
    return _fallbackTripApprovalCheck(user);
  }

  // Async method to pre-fetch config (call this at app startup)
  static Future<void> preloadApprovalConfig() async {
    try {
      final response = await ApiService.getMenuApprovalConfig();
      if (response != null && response['success'] == true) {
        _cachedApprovalConfig = response['data'];
        _lastConfigFetch = DateTime.now();
      }
    } catch (e) {
      print('Error preloading approval config: $e');
    }
  }

  // Refresh config when needed
  static Future<void> refreshApprovalConfig() async {
    try {
      final response = await ApiService.getMenuApprovalConfig();
      if (response != null && response['success'] == true) {
        _cachedApprovalConfig = response['data'];
        _lastConfigFetch = DateTime.now();
      }
    } catch (e) {
      print('Error refreshing approval config: $e');
    }
  }

  // Fallback check if no config is available
  static bool _fallbackTripApprovalCheck(User user) {
    if (user.role == UserRole.admin || 
        user.role == UserRole.hr) {
      return true;
    }
    
    // Check if user is department head
    return user.authenticationLevel >= 2;
  }

  // Check if user is department head (for primary approval)
  //static bool isDepartmentHead(User user) {
  //  return user.authenticationLevel >= 2;
  //}

  // Check if user is safety department (for safety approvals)
  //static bool isSafetyDepartment(User user) {
  //  return user.role == UserRole.security;
  //}

  // Check if user can access admin console
  static bool canAccessAdminConsole(User user) {
    return user.role == UserRole.sysadmin;
  }
  
  // Clear cache
  static void clearCache() {
    _cachedApprovalConfig = null;
    _lastConfigFetch = null;
  }
}