import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/notification_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/profile_screens/profile_screen.dart';

class TopBar extends StatelessWidget {
  final User user;
  final VoidCallback onMenuTap;
  final int notificationCount; // Add notification count

  const TopBar({
    Key? key,
    required this.user,
    required this.onMenuTap,
    this.notificationCount = 0, // Default to 0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 80,
          leading: IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: onMenuTap,
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text(
              'PCW RIDE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            // Notification Icon with Badge
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationScreen(userId: '1', token: '1',),
                      ),
                    );
                  },
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        notificationCount > 9
                            ? '9+'
                            : notificationCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            // Avatar with click functionality
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: user),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: Colors.yellow[600],
                  child: Text(
                    _getAvatarText(),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
}
