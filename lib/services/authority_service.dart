// services/authority_service.dart
import '../models/user_model.dart';

class AuthorityService {
  // Check if user has user creation authority
  static bool hasUserCreationAuthority(User user) {
    // Implement your logic based on:
    // - User configuration in database
    // - Department head status
    // - Specific user IDs configured for this authority
    // - Authentication level
    
    // Example implementation:
    if (user.role == UserRole.hr || 
        user.role == UserRole.admin || 
        user.role == UserRole.sysadmin) {
      return true;
    }
    
    if (user.role == UserRole.employee) {
      // Check if this employee is configured for user creation
      // This could come from user configuration in your database
      return user.authenticationLevel == 1;
    }
    
    return false;
  }

  // Check if user has trip approval authority
  static bool hasTripApprovalAuthority(User user) {
    // Implement logic based on:
    // - Department head status
    // - Approval policy configuration
    // - Specific user roles
    
    if (user.role == UserRole.admin || 
        user.role == UserRole.sysadmin ||
        user.role == UserRole.security) {
      return true;
    }
    
    if (user.role == UserRole.employee) {
      // Check if this employee is a department head or configured approver
      return user.authenticationLevel == 2;
    }
    
    return false;
  }

  // Check if user is department head (for primary approval)
  static bool isDepartmentHead(User user) {
    // Implement department head check logic
    return user.authenticationLevel >= 2;
  }

  // Check if user is safety department (for safety approvals)
  static bool isSafetyDepartment(User user) {
    return user.role == UserRole.security;
  }

  // Check if user can access admin console
  static bool canAccessAdminConsole(User user) {
    return user.role == UserRole.sysadmin;
  }
  
}