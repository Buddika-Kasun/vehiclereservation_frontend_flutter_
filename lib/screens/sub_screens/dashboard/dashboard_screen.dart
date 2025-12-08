import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard/role_widgets/admin_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard/role_widgets/dashboard_top_panels.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard/role_widgets/driver_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard/role_widgets/employee_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard/role_widgets/hr_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard/role_widgets/security_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/trip/create_trip_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  bool _isLoading = true;
  UserRole _userRole = UserRole.employee;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = StorageService.userData;
      
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _user = user;
        _userRole = user.role;
        _isLoading = false;
      });
    } catch (e) {
      print('Load user data error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRoleBasedDashboard(UserRole role) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    switch (role) {
      case UserRole.admin:
      case UserRole.sysadmin:
        return AdminDashboardContent(user: _user);
      case UserRole.driver:
        return DriverDashboardContent(user: _user);
      case UserRole.security:
        return SecurityDashboardContent(user: _user);
      case UserRole.hr:
        return HrDashboardContent(user: _user);
      case UserRole.employee:
      default:
        return EmployeeDashboardContent(user: _user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Role-based top section
          DashboardTopPanel(
            user: _user,
            userRole: _userRole,
            isLoading: _isLoading,
            onCreateTrip: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateTripScreen()),
              );
            },
            onNearbyVehicles: () {
              print('Nearby Vehicles clicked');
            },
            onGoOnline: () {
              print('Go Online clicked');
            },
            onGoOffline: () {
              print('Go Offline clicked');
            },
            onQuickScan: () {
              print('Quick Scan clicked');
            },
          ),
          
          // Role-based dashboard content
          Expanded(
            child: _buildRoleBasedDashboard(_userRole),
          ),
        ],
      ),
    );
  }
}