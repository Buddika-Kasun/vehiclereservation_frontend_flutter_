import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/constant.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

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

  List<MenuItem> _getMenuItems() {
    if (isAdminConsole) {
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

    items.add(MenuItem(Icons.home, 'Home'));

    if (user.canUserCreate) {
      items.add(MenuItem(Icons.person_add, 'User Creations'));
    }

    if (user.canTripApprove) {
      items.add(MenuItem(Icons.verified, 'Trip Approvals'));
    }

    switch (user.role) {
      case UserRole.employee:
        items.add(MenuItem(Icons.directions_car, 'My Rides'));
        break;

      case UserRole.hr:
      case UserRole.manager:
      case UserRole.admin:
        items.add(MenuItem(Icons.directions_car, 'My Rides'));
        break;

      case UserRole.sysadmin:
        items.addAll([
          MenuItem(Icons.directions_car, 'All Rides'),
          MenuItem(Icons.verified, 'Review Trips'),
          MenuItem(Icons.car_rental_sharp, 'All Vehicles'),
          MenuItem(Icons.verified, 'Meter Reading'),
          MenuItem(Icons.directions_car, 'Assigned Rides'),
          MenuItem(
            Icons.admin_panel_settings,
            'Admin Console',
            isSysAdmin: true,
          ),
        ]);
        break;

      case UserRole.security:
        items.add(MenuItem(Icons.verified, 'Meter Reading'));
        break;

      case UserRole.supervisor:
        items.addAll([
          MenuItem(Icons.directions_car, 'My Rides'),
          MenuItem(Icons.car_rental_sharp, 'My Vehicles'),
          MenuItem(Icons.directions_car, 'Assigned Rides'),
          MenuItem(Icons.verified, 'Review Trips'),
        ]);
        break;

      case UserRole.driver:
        items.addAll([
          MenuItem(Icons.car_rental_sharp, 'My Vehicles'),
          MenuItem(Icons.directions_car, 'Assigned Rides'),
        ]);
        break;
    }

    return items;
  }

  String _getRoleDisplayName() {
    if (isAdminConsole) return 'Admin Console';

    switch (user.role) {
      case UserRole.sysadmin:
        return 'System Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.hr:
        return 'HR Manager';
      case UserRole.manager:
        return 'Manager';
      case UserRole.security:
        return 'Security';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.driver:
        return 'Driver';
      case UserRole.employee:
        if (user.canUserCreate && user.canTripApprove) {
          return 'Employee (Both Authorities)';
        } else if (user.canUserCreate) {
          return 'Employee (User Creation)';
        } else if (user.canTripApprove) {
          return 'Employee (Trip Approval)';
        }
        return 'Employee';
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems();

    return Drawer(
      child: Column(
        children: [
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
                  onBackToMain!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              isAdminConsole ? 'Admin Console' : 'PCW RIDE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),

          if (!isAdminConsole) _buildUserCard(),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.yellow[800]!, Colors.yellow[600]!],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),

                            ...menuItems.map(
                              (item) => _buildMenuItem(item, context),
                            ),

                            const Spacer(),

                            _buildLogout(context),

                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Text(
            user.displayname,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getRoleDisplayName(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email ?? 'No mail',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(user.phone, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[800]!, const Color.fromARGB(205, 244, 67, 54)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
        onTap: () {
          Navigator.pop(context);
          onMenuTap('Log Out');
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Developed by ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  const Color.fromARGB(255, 0, 73, 200),
                  const Color.fromARGB(255, 18, 105, 255),
                  const Color.fromARGB(255, 56, 129, 255),
                  const Color.fromARGB(255, 78, 143, 254),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                tileMode: TileMode.mirror,
              ).createShader(bounds);
            },
            child: Text(
              'Axperia',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white, // This will be replaced by gradient
                
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
    }
    if (user.displayname.isNotEmpty) {
      return user.displayname[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildMenuItem(MenuItem item, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.isSysAdmin
              ? [
                  const Color.fromARGB(97, 243, 58, 58),
                  const Color.fromARGB(10, 174, 65, 65),
                ]
              : [const Color.fromARGB(28, 5, 3, 0), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: item.isSysAdmin
              ? const Color.fromARGB(255, 210, 28, 16)
              : Colors.black,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: item.isSysAdmin
                ? const Color.fromARGB(255, 210, 28, 16)
                : Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: item.isSysAdmin
              ? const Color.fromARGB(255, 210, 28, 16)
              : Colors.grey[600],
        ),
        onTap: () {
          if (isAdminConsole) {
            Navigator.pop(context);
            onMenuTap('Admin: ${item.title}');
          } else if (item.isSysAdmin) {
            onMenuTap('Open Admin Console');
          } else {
            Navigator.pop(context);
            onMenuTap(item.title);
          }
        },
      ),
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final bool isSysAdmin;

  MenuItem(this.icon, this.title, {this.isSysAdmin = false});
}
