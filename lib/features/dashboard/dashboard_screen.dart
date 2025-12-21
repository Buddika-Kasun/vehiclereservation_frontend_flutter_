import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/dashboard_stats.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/role_widgets/admin_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/role_widgets/dashboard_top_panels.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/role_widgets/driver_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/role_widgets/employee_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/role_widgets/hr_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/role_widgets/security_dashboard.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/create_trip_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  User? _user;
  DashboardStats? _dashboardStats;
  bool _isLoading = true;
  UserRole _userRole = UserRole.employee;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void handleScreenRefresh(Map<String, dynamic> data) {
    // Handle live dashboard stats updates
    final scope = data['scope'] ?? 'ALL';
    if (scope == 'STATS' || scope == 'ALL') {
      // Refresh dashboard data
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await ApiService.getDashboardStats();
      setState(() {
        _dashboardStats = stats;
      });
    } catch (e) {
      print('Load dashboard stats error: $e');
    }
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
      
      // Load stats after user data is ready
      _loadDashboardData();
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
        return AdminDashboardContent(user: _user, stats: _dashboardStats?.admin);
      case UserRole.driver:
        return DriverDashboardContent(user: _user); // TODO: Add driver stats
      case UserRole.security:
        return SecurityDashboardContent(user: _user);
      case UserRole.hr:
      case UserRole.manager:
        return HrDashboardContent(user: _user, stats: _dashboardStats?.manager);
      case UserRole.employee:
      default:
        return EmployeeDashboardContent(user: _user, stats: _dashboardStats?.employee);
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
