// lib/core/routes/app_routes.dart
class AppRoutes {
  // External routes (outside HomeScreen)
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String adminLogin = '/admin-login';

  static const String tripDetails = '/trip-details';
  static const String myRideTripDetails = '/my-ride-trip-details';
  static const String reviewTripDetails = '/review-trip-details';
  static const String approvalTripDetails = '/approval-trip-details';
  static const String assignRideTripDetails = '/assign-ride-trip-details';

  // Main container route (HomeScreen with internal navigation)
  static const String home = '/home';

  // Internal routes (these are handled inside HomeScreen)
  // Add all your screen routes here
  static const String dashboard = '/dashboard';
  static const String userCreations = '/user-creations'; // Add this
  static const String myRides = '/my-rides';
  static const String allRides = '/all-rides';
  static const String allTrips = '/all-trips';
  static const String assignedRides = '/assigned-rides';
  static const String reviewTrips = '/review-trips';
  static const String meterReading = '/meter-reading';
  static const String tripApprovals = '/trip-approvals';
  static const String notifications = '/notifications';
  static const String myVehicles = '/my-vehicles';
  static const String allVehicles = '/all-vehicles';

  // Admin routes (inside HomeScreen)
  static const String companyManagement = '/admin/company';
  static const String departmentManagement = '/admin/department';
  static const String costCenterManagement = '/admin/cost-center';
  static const String vehicleManagement = '/admin/vehicle';
  static const String vehicleTypeManagement = '/admin/vehicle-type';
  static const String approvalManagement = '/admin/approval';
  static const String approvalUsers = '/admin/approval-users';

  // Check if a route is internal
  static bool isInternalRoute(String route) {
    final internalRoutes = [
      dashboard,
      userCreations,
      myRides,
      allRides,
      allTrips,
      assignedRides,
      reviewTrips,
      meterReading,
      tripApprovals,
      myVehicles,
      allVehicles,
      companyManagement,
      departmentManagement,
      costCenterManagement,
      vehicleManagement,
      vehicleTypeManagement,
      approvalManagement,
      approvalUsers,
    ];
    return internalRoutes.contains(route);
  }
}

// Helper to extract screen name from route
class RouteHelper {
  // Convert route to HomeScreen screen name
  static String? getHomeScreenNameFromRoute(String route) {
    final routeMap = {
      AppRoutes.dashboard: 'dashboard',
      AppRoutes.myRides: 'my_rides',
      AppRoutes.allRides: 'all_rides',
      AppRoutes.allTrips: 'all_trips',
      AppRoutes.assignedRides: 'assigned_rides',
      AppRoutes.reviewTrips: 'review_trips',
      AppRoutes.meterReading: 'meter_reading',
      AppRoutes.userCreations: 'user_creations', 
      AppRoutes.tripApprovals: 'trip_approvals',
      AppRoutes.myVehicles: 'my_vehicles',
      AppRoutes.allVehicles: 'all_vehicles',
      AppRoutes.companyManagement: 'company_management',
      AppRoutes.departmentManagement: 'department_management',
      AppRoutes.costCenterManagement: 'cost_center_management',
      AppRoutes.vehicleManagement: 'vehicle_management',
      AppRoutes.vehicleTypeManagement: 'vehicle_type_management',
      AppRoutes.approvalManagement: 'approval_management',
      AppRoutes.approvalUsers: 'approval_users',
    };

    return routeMap[route];
  }
}
