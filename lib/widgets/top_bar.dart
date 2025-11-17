import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/home_screen.dart';

class TopBar extends StatelessWidget {
  final User user;
  final VoidCallback onMenuTap;

  const TopBar({
    Key? key,
    required this.user,
    required this.onMenuTap,
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
          // In TopBar widget
          title: GestureDetector(
            onTap: () {
              // Navigate to home screen
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
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.yellow[600],
                child: Text(
                  _getAvatarText(),
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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