import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../widgets/side_menu.dart';
import '../widgets/top_bar.dart';
import 'login_screen.dart';

// Import all the screens
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/dashboard_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/rides_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/user_creations_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/approvals_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/admin/company_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/admin/department_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/admin/cost_center_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/admin/vehicle_management_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/admin/approval_management_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _user;
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
      
      if (user == null) {
        setState(() {
          _redirectToLogin = true;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Load user data error: $e');
      setState(() {
        _redirectToLogin = true;
        _isLoading = false;
      });
    }
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
      case 'Rides':
      case 'My Rides':
        _navigateToRides();
        break;
      case 'User Creations':
      case 'Pending User Creations':
        _navigateToUserCreations();
        break;
      case 'Approvals':
      case 'Pending Trip Approvals':
      case 'Safety Approvals':
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

  void _navigateToRides() {
    setState(() {
      _currentScreen = RidesScreen();
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
      case 'Approvals':
        _navigateToAdminApprovalManagement();
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
      _currentScreen = DepartmentManagementScreen();
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

  void _navigateToAdminApprovalManagement() {
    setState(() {
      _currentScreen = ApprovalManagementScreen();
    });
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
          ),
          
          Expanded(
            child: _currentScreen,
          ),
        ],
      ),
    );
  }
}