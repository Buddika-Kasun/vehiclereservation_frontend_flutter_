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
        return AdminDashboardContent(
          user: _user,
          stats: _dashboardStats?.admin,
        );
      case UserRole.driver:
        return DriverDashboardContent(user: _user);
      case UserRole.security:
        return SecurityDashboardContent(user: _user);
      case UserRole.hr:
      case UserRole.manager:
        return HrDashboardContent(user: _user, stats: _dashboardStats?.manager);
      case UserRole.employee:
      case UserRole.supervisor:
      default:
        return EmployeeDashboardContent(
          user: _user,
          stats: _dashboardStats?.employee,
        );
    }
  }

  // Method to show gradient error dialog
  void _showErrorDialog({
    required String title,
    required String message,
    bool isSuccess = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSuccess
                  ? [
                      Colors.green.withOpacity(0.85),
                      Colors.lightGreen.withOpacity(0.85),
                    ]
                  : [
                      Colors.red.withOpacity(0.85),
                      Colors.orange.withOpacity(0.85),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isSuccess ? Colors.green : Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black26,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to handle trip creation with error dialog
  Future<void> _handleCreateTrip() async {
    try {
      final response = await ApiService.checkTripCreationEligibility();

      print('Response: $response');

      if (response.containsKey('success')) {
        if (response['success'] == true) {
          if (response['data'] != null &&
              response['data']['canCreateTrip'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateTripScreen()),
            );
          } else {
            _showErrorDialog(
              title: 'Cannot Create Trip',
              message: response['message'] ?? 'Cannot create trip at this time',
              isSuccess: false,
            );
          }
        } else {
          _showErrorDialog(
            title: 'Error',
            message: response['message'] ?? 'Failed to create trip',
            isSuccess: false,
          );
        }
      } else {
        _showErrorDialog(
          title: 'Server Error',
          message: 'Invalid response from server',
          isSuccess: false,
        );
      }
    } catch (e) {
      print('Error in onCreateTrip: $e');
      _showErrorDialog(
        title: 'Network Error',
        message: 'Connection failed: ${e.toString()}',
        isSuccess: false,
      );
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
            onCreateTrip: _handleCreateTrip,
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
          Expanded(child: _buildRoleBasedDashboard(_userRole)),
        ],
      ),
    );
  }
}
