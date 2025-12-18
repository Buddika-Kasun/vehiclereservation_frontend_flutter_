import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class DashboardTopPanel extends StatelessWidget {
  final User? user;
  final UserRole userRole;
  final bool isLoading;
  final VoidCallback onCreateTrip;
  final VoidCallback onNearbyVehicles;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;
  final VoidCallback onQuickScan;

  const DashboardTopPanel({
    Key? key,
    required this.user,
    required this.userRole,
    required this.isLoading,
    required this.onCreateTrip,
    required this.onNearbyVehicles,
    required this.onGoOnline,
    required this.onGoOffline,
    required this.onQuickScan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.only(top: 20, bottom: 26, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    switch (userRole) {
      case UserRole.driver:
        return DriverTopPanel(user: user, onGoOnline: onGoOnline, onGoOffline: onGoOffline);
      case UserRole.security:
        return SecurityTopPanel(user: user, onQuickScan: onQuickScan);
      case UserRole.hr:
      case UserRole.manager:
        return HrTopPanel(user: user);
      case UserRole.admin:
      case UserRole.sysadmin:
        return AdminTopPanel(user: user, onCreateTrip: onCreateTrip, onNearbyVehicles: onNearbyVehicles);
      case UserRole.employee:
      default:
        return EmployeeTopPanel(user: user, onCreateTrip: onCreateTrip, onNearbyVehicles: onNearbyVehicles);
    }
  }
}

// DRIVER Top Panel
class DriverTopPanel extends StatelessWidget {
  final User? user;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;

  const DriverTopPanel({
    Key? key,
    required this.user,
    required this.onGoOnline,
    required this.onGoOffline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 26, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Driver Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (user != null)
            Text(
              'Welcome, ${user!.displayname}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onGoOnline,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Go Online',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: onGoOffline,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Go Offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SECURITY Top Panel
class SecurityTopPanel extends StatelessWidget {
  final User? user;
  final VoidCallback onQuickScan;

  const SecurityTopPanel({
    Key? key,
    required this.user,
    required this.onQuickScan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 0, bottom: 26, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Security Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (user != null)
            Text(
              'Welcome, ${user!.displayname}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: onQuickScan,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow, Colors.orange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.black, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'QUICK SCAN',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// HR Top Panel
class HrTopPanel extends StatelessWidget {
  final User? user;

  const HrTopPanel({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 26, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'HR Approval Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (user != null)
            Text(
              'Welcome, ${user!.displayname}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to approvals screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              'View Pending Approvals',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ADMIN Top Panel
class AdminTopPanel extends StatelessWidget {
  final User? user;
  final VoidCallback onCreateTrip;
  final VoidCallback onNearbyVehicles;

  const AdminTopPanel({
    Key? key,
    required this.user,
    required this.onCreateTrip,
    required this.onNearbyVehicles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 0, bottom: 26, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (user != null)
            Text(
              'Welcome, ${user!.displayname}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCreateTrip,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow, Colors.orange],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Create New Trip',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: onNearbyVehicles,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nearby Vehicles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// EMPLOYEE Top Panel
class EmployeeTopPanel extends StatelessWidget {
  final User? user;
  final VoidCallback onCreateTrip;
  final VoidCallback onNearbyVehicles;

  const EmployeeTopPanel({
    Key? key,
    required this.user,
    required this.onCreateTrip,
    required this.onNearbyVehicles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 26, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Employee Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (user != null)
            Text(
              'Welcome, ${user!.displayname}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCreateTrip,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.yellow[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Create New Trip',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: onNearbyVehicles,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nearby Vehicles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
