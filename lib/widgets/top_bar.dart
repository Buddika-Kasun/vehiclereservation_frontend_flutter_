import 'package:flutter/material.dart';
import '../models/user_model.dart';

class TopBar extends StatelessWidget {
  final User user;
  final VoidCallback onMenuTap;
  final VoidCallback onCreateTrip;
  final VoidCallback onNearbyVehicles;

  const TopBar({
    Key? key,
    required this.user,
    required this.onMenuTap,
    required this.onCreateTrip,
    required this.onNearbyVehicles,
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
          title: Text(
            'PCW RIDE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
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
        
        // Create Trip & Nearby Vehicles Buttons
        Container(
          padding: const EdgeInsets.only(top: 20, bottom: 26, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
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