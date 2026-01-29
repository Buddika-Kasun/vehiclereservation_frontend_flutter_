class DashboardStats {
  final Map<String, dynamic>? admin;
  final Map<String, dynamic>? manager;
  final Map<String, dynamic>? employee;

  DashboardStats({
    this.admin,
    this.manager,
    this.employee,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      admin: json['admin'] as Map<String, dynamic>?,
      manager: json['manager'] as Map<String, dynamic>?,
      employee: json['employee'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin': admin,
      'manager': manager,
      'employee': employee,
    };
  }
}

class AdminStats {
  final int totalUsers;
  final int totalPendingUsers;
  final int totalTripsToday;
  final int activeVehicles;

  AdminStats({
    required this.totalUsers,
    required this.totalPendingUsers,
    required this.totalTripsToday,
    required this.activeVehicles,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalPendingUsers: json['totalPendingUsers'] ?? 0,
      totalTripsToday: json['totalTripsToday'] ?? 0,
      activeVehicles: json['activeVehicles'] ?? 0,
    );
  }
}

class ManagerStats {
  final int pendingTripApprovals;
  final int departmentActiveTrips;
  final int departmentTotalUsers;

  ManagerStats({
    required this.pendingTripApprovals,
    required this.departmentActiveTrips,
    required this.departmentTotalUsers,
  });

  factory ManagerStats.fromJson(Map<String, dynamic> json) {
    return ManagerStats(
      pendingTripApprovals: json['pendingTripApprovals'] ?? 0,
      departmentActiveTrips: json['departmentActiveTrips'] ?? 0,
      departmentTotalUsers: json['departmentTotalUsers'] ?? 0,
    );
  }
}

class EmployeeStats {
  final int myTotalTrips;
  final int myUpcomingTrips;
  final int myNotificationsCount;

  EmployeeStats({
    required this.myTotalTrips,
    required this.myUpcomingTrips,
    required this.myNotificationsCount,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      myTotalTrips: json['myTotalTrips'] ?? 0,
      myUpcomingTrips: json['myUpcomingTrips'] ?? 0,
      myNotificationsCount: json['myNotificationsCount'] ?? 0,
    );
  }
}
