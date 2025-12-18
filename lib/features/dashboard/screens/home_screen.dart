// File: lib/screens/home_screen.dart
// Added: screenName parameter to navigate to specific child screens

import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/approval_user_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicleType_managemnet_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/approval/rides_approval_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/assigned/assigned_rides_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/global_websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/side_menu.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/top_bar.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';

// Import all the screens
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/dashboard_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/ride/rides_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/creations/user_creations_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/approval/approvals_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/company_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/department_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/cost_center_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/approval_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? screenName; // NEW: Optional screen name to navigate to
  final Map<String, dynamic>? screenData; // NEW: Optional data for the screen

  const HomeScreen({Key? key, this.screenName, this.screenData})
    : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _user;
  String? _token;
  bool _isLoading = true;
  bool _redirectToLogin = false;
  bool _showAdminConsole = false;

  // Current screen state - Start with Dashboard
  Widget _currentScreen = DashboardScreen();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle navigation when widget is updated with new screenName
    if (widget.screenName != null &&
        widget.screenName != oldWidget.screenName) {
      _navigateToScreen(widget.screenName!, widget.screenData);
    }
  }

  Future<void> _checkAuthentication() async {
    try {
      final hasValidSession = await StorageService.hasValidSession;

      if (!hasValidSession) {
        setState(() {
          _redirectToLogin = true;
          _isLoading = false;
        });
        return;
      }

      await _loadUserData();
    } catch (e) {
      print('Authentication error: $e');
      setState(() {
        _redirectToLogin = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = StorageService.userData;
      final token = await SecureStorageService().accessToken;

      if (user == null || token == null) {
        setState(() {
          _redirectToLogin = true;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _user = user;
        _token = token;
        _isLoading = false;
      });

      // Navigate to requested screen after user data is loaded
      if (widget.screenName != null) {
        _navigateToScreen(widget.screenName!, widget.screenData);
      }
    } catch (e) {
      print('Load user data error: $e');
      setState(() {
        _redirectToLogin = true;
        _isLoading = false;
      });
    }
  }

  // NEW: Method to navigate to a specific screen by name
  void _navigateToScreen(String screenName, Map<String, dynamic>? data) {
    if (_user == null) return; // Wait for user data to load

    setState(() {
      switch (screenName) {
        case 'dashboard':
          _currentScreen = DashboardScreen();
          break;
        case 'my_rides':
        case 'all_rides':
          _currentScreen = RidesScreen(userId: data?['userId'] ?? _user!.id);
          break;
        case 'my_vehicles':
          _currentScreen = VehicleScreen(user: data?['user'] ?? _user!);
          break;
        case 'assigned_rides':
          _currentScreen = AssignedRidesScreen(userId: _user!.id);
          break;
        case 'meter_reading':
          _currentScreen = RidesApprovalScreen();
          break;
        case 'user_creations':
          _currentScreen = UserCreationsScreen();
          break;
        case 'trip_approvals':
          _currentScreen = ApprovalsScreen();
          break;
        case 'company_management':
          _currentScreen = CompanyManagementScreen();
          break;
        case 'department_management':
          _currentScreen = DepartmentsManagementScreen();
          break;
        case 'cost_center_management':
          _currentScreen = CostCenterManagementScreen();
          break;
        case 'vehicle_management':
          _currentScreen = VehicleManagementScreen();
          break;
        case 'vehicle_type_management':
          _currentScreen = VehicleTypeManagementScreen();
          break;
        case 'approval_management':
          _currentScreen = ApprovalManagementScreen(
            onApprovalUsersPressed: _switchToApprovalUsersScreen,
          );
          break;
        case 'approval_users':
          _currentScreen = ApprovalUsersScreen(
            onBackToApprovalConfig: _switchToApprovalManagementScreen,
          );
          break;
        default:
          _currentScreen = DashboardScreen();
      }
    });
  }

  void _handleMenuTap(String menuItem) async {
    // Close drawer first for all menu items
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }

    if (menuItem == 'Open Admin Console') {
      // Open Admin Console sidebar
      setState(() {
        _showAdminConsole = true;
      });
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    if (menuItem.startsWith('Admin: ')) {
      final adminItem = menuItem.replaceFirst('Admin: ', '');
      _handleAdminMenuItem(adminItem);
      return;
    }

    switch (menuItem) {
      case 'Log Out':
        await _showLogoutDialog();
        break;
      case 'Name':
        _showUserProfile();
        break;
      case 'Home':
        _navigateToDashboard();
        break;
      case 'My Vehicles':
        _navigateToVehicles();
        break;
      case 'My Rides':
      case 'All Rides':
        _navigateToRides();
        break;
      case 'Meter Reading':
        _navigateToRideApprovals();
        break;
      case 'Assigned Rides':
        _navigateToAssignedRides();
        break;
      case 'User Creations':
        _navigateToUserCreations();
        break;
      case 'Trip Approvals':
        _navigateToApprovals();
        break;
    }
  }

  void _handleBackToMain() {
    setState(() {
      _showAdminConsole = false;
    });
  }

  // Navigation methods
  void _navigateToDashboard() {
    setState(() {
      _currentScreen = DashboardScreen();
    });
  }

  // In your logout function
  Future<void> logout() async {
    try {
      // Clear WebSocket connection
      final manager = GlobalWebSocketManager();
      await manager.disconnect();
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }

    // Clear storage and navigate to login
    await StorageService.clearUserData();
    await SecureStorageService().clearTokens();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToRides() {
    setState(() {
      _currentScreen = RidesScreen(userId: _user!.id);
    });
  }

  void _navigateToRideApprovals() {
    setState(() {
      _currentScreen = RidesApprovalScreen();
    });
  }

  void _navigateToAssignedRides() {
    setState(() {
      _currentScreen = AssignedRidesScreen(userId: _user!.id);
    });
  }

  void _navigateToVehicles() {
    setState(() {
      _currentScreen = VehicleScreen(user: _user!);
    });
  }

  void _navigateToUserCreations() {
    setState(() {
      _currentScreen = UserCreationsScreen();
    });
  }

  void _navigateToApprovals() {
    setState(() {
      _currentScreen = ApprovalsScreen();
    });
  }

  void _navigateToApprovalUsers() {
    setState(() {
      _currentScreen = ApprovalUsersScreen();
    });
  }

  void _handleAdminMenuItem(String adminItem) {
    switch (adminItem) {
      case 'Company':
        _navigateToCompanyManagement();
        break;
      case 'Departments':
        _navigateToDepartmentManagement();
        break;
      case 'Cost Centers':
        _navigateToCostCenterManagement();
        break;
      case 'Vehicles':
        _navigateToVehicleManagement();
        break;
      case 'Vehicle Types':
        _navigateToVehicleTypeManagement();
        break;
      case 'Approvals':
        _navigateToAdminApprovalManagement();
        break;
      case 'Approval Users':
        _navigateToApprovalUsers();
        break;
    }
  }

  void _navigateToCompanyManagement() {
    setState(() {
      _currentScreen = CompanyManagementScreen();
    });
  }

  void _navigateToDepartmentManagement() {
    setState(() {
      _currentScreen = DepartmentsManagementScreen();
    });
  }

  void _navigateToCostCenterManagement() {
    setState(() {
      _currentScreen = CostCenterManagementScreen();
    });
  }

  void _navigateToVehicleManagement() {
    setState(() {
      _currentScreen = VehicleManagementScreen();
    });
  }

  void _navigateToVehicleTypeManagement() {
    setState(() {
      _currentScreen = VehicleTypeManagementScreen();
    });
  }

  // Add this method to handle switching between approval screens
  void _switchToApprovalUsersScreen() {
    setState(() {
      _currentScreen = ApprovalUsersScreen(
        onBackToApprovalConfig: _switchToApprovalManagementScreen,
      );
    });
  }

  void _switchToApprovalManagementScreen() {
    setState(() {
      _currentScreen = ApprovalManagementScreen(
        onApprovalUsersPressed: _switchToApprovalUsersScreen,
      );
    });
  }

  // Update your existing method to use the new approach
  void _navigateToAdminApprovalManagement() {
    _switchToApprovalManagementScreen();
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(197, 255, 65, 65),
                Color.fromARGB(215, 255, 50, 43),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Stay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(111, 196, 0, 0),
                              Color.fromARGB(255, 196, 0, 0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              196,
                              0,
                              0,
                            ).withOpacity(0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF416C).withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => logout(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 6),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await StorageService.clearUserData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _showUserProfile() {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_user?.displayname ?? 'N/A'}'),
            Text('Email: ${_user?.email ?? 'N/A'}'),
            Text('Phone: ${_user?.phone ?? 'N/A'}'),
            Text('Role: ${_user?.role.displayName ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_redirectToLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('User data not available'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: SideMenu(
        user: _user!,
        onMenuTap: _handleMenuTap,
        isAdminConsole: _showAdminConsole,
        onBackToMain: _showAdminConsole ? _handleBackToMain : null,
      ),
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          setState(() {
            _showAdminConsole = false;
          });
        }
      },
      body: Column(
        children: [
          TopBar(
            user: _user!,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            token: _token!,
          ),
          Expanded(child: _currentScreen),
        ],
      ),
    );
  }
}

