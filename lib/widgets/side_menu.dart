import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/services/authority_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';
import '../models/user_model.dart';

class SideMenu extends StatelessWidget {
  final User user;
  final Function(String) onMenuTap;
  final bool isAdminConsole;
  final VoidCallback? onBackToMain;

  const SideMenu({
    Key? key,
    required this.user,
    required this.onMenuTap,
    this.isAdminConsole = false,
    this.onBackToMain,
  }) : super(key: key);

  // Define menu items based on user role and authority
  List<MenuItem> _getMenuItems() {
    if (isAdminConsole) {
      // Admin Console menu items
      return [
        MenuItem(Icons.business, 'Company'),
        MenuItem(Icons.account_balance_wallet, 'Cost Centers'),
        MenuItem(Icons.account_balance, 'Departments'),
        MenuItem(Icons.directions_bus, 'Vehicle Types'),
        MenuItem(Icons.directions_car, 'Vehicles'),
        MenuItem(Icons.verified, 'Approvals'),
      ];
    }

    final items = <MenuItem>[];
    
    switch (user.role) {
      case UserRole.employee:
        final hasUserCreationAuthority = AuthorityService.hasUserCreationAuthority(user);
        final hasTripApprovalAuthority = AuthorityService.hasTripApprovalAuthority(user);
        
        items.addAll([
          MenuItem(Icons.home, 'Home'),
          MenuItem(Icons.directions_car, 'My Rides'),
        ]);
        
        if (hasUserCreationAuthority) {
          items.add(MenuItem(Icons.person_add, 'Pending User Creations'));
        }
        
        if (hasTripApprovalAuthority) {
          items.add(MenuItem(Icons.verified, 'Pending Trip Approvals'));
        }
        break;
        
      case UserRole.hr:
      case UserRole.admin:
        items.addAll([
          MenuItem(Icons.home, 'Home'),
          MenuItem(Icons.directions_car, 'Rides'),
          MenuItem(Icons.person_add, 'User Creations'),
          MenuItem(Icons.verified, 'Approvals'),
        ]);
        break;
        
      case UserRole.sysadmin:
        items.addAll([
          MenuItem(Icons.home, 'Home'),
          MenuItem(Icons.directions_car, 'Rides'),
          MenuItem(Icons.person_add, 'User Creations'),
          MenuItem(Icons.verified, 'Approvals'),
          MenuItem(Icons.admin_panel_settings, 'Admin Console', isSysAdmin: true),
        ]);
        break;
        
      case UserRole.security:
        items.addAll([
          MenuItem(Icons.home, 'Home'),
          MenuItem(Icons.directions_car, 'My Rides'),
          MenuItem(Icons.verified, 'Safety Approvals'),
        ]);
        break;
        
      case UserRole.driver:
        items.addAll([
          MenuItem(Icons.home, 'Home'),
          MenuItem(Icons.directions_car, 'My Rides'),
        ]);
        break;
    }
    
    items.add(MenuItem(Icons.logout, 'Log Out', isLogout: true));
    
    return items;
  }

  String _getRoleDisplayName() {
    if (isAdminConsole) {
      return 'Admin Console';
    }
    
    switch (user.role) {
      case UserRole.sysadmin:
        return 'System Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.hr:
        return 'HR Manager';
      case UserRole.security:
        return 'Security';
      case UserRole.driver:
        return 'Driver';
      case UserRole.employee:
        final hasUserCreation = AuthorityService.hasUserCreationAuthority(user);
        final hasTripApproval = AuthorityService.hasTripApprovalAuthority(user);
        
        if (hasUserCreation && hasTripApproval) {
          return 'Employee (Both Authorities)';
        } else if (hasUserCreation) {
          return 'Employee (User Creation)';
        } else if (hasTripApproval) {
          return 'Employee (Trip Approval)';
        } else {
          return 'Employee';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems();
    
    return Drawer(
      child: Column(
        children: [
          // Header Section - SAME STYLE FOR BOTH
          AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            toolbarHeight: 80,
            leading: IconButton(
              icon: Icon(
                isAdminConsole ? Icons.arrow_back : Icons.close,
                color: Colors.white,
              ),
              onPressed: () {
                if (isAdminConsole && onBackToMain != null) {
                  // Go back to main sidebar without closing drawer
                  onBackToMain!();
                } else {
                  // Close the drawer
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              isAdminConsole ? 'Admin Console' : 'PCW RIDE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          
          // User Card (only show in main sidebar)
          if (!isAdminConsole) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              color: AppColors.primary,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getAvatarText(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.displayname,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getRoleDisplayName(),
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
          
          // Menu Items - SAME STYLE FOR BOTH
          Expanded(
            child: Container(
              color: AppColors.secondary, // Same background color for both
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: 10),
                  ...menuItems.map((item) => _buildMenuItem(item, context)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAvatarText() {
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      return user.profilePicture![0].toUpperCase();
    } else if (user.displayname.isNotEmpty) {
      return user.displayname[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildMenuItem(MenuItem item, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        top: item.isLogout ? 16 : 0,
        bottom: item.isLogout ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: item.isLogout ? Colors.red : Colors.transparent,
        borderRadius: item.isLogout 
            ? BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: _getIconColor(item),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: _getTextColor(item),
            fontWeight: FontWeight.w900,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[600],
          size: 16,
        ),
        onTap: () {
          if (isAdminConsole) {
            Navigator.pop(context);
            onMenuTap('Admin: ${item.title}');
          } else if (item.title == 'Admin Console') {
            // Don't close drawer, just switch to admin console
            onMenuTap('Open Admin Console');
          } else {
            Navigator.pop(context);
            onMenuTap(item.title);
          }
        },
      ),
    );
  }

  Color _getIconColor(MenuItem item) {
    if (item.isLogout) {
      return Colors.white;
    } else if (item.isSysAdmin) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  Color _getTextColor(MenuItem item) {
    if (item.isLogout) {
      return Colors.white;
    } else if (item.isSysAdmin) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final bool isLogout;
  final bool isSysAdmin;

  MenuItem(this.icon, this.title, {this.isLogout = false, this.isSysAdmin = false});
}