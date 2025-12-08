import 'package:flutter/material.dart';

class AssignedRideScreen extends StatelessWidget {
  final int userId;

  const AssignedRideScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              " Assigned Trip Screen", 
              style: TextStyle(color: Colors.white, fontSize: 24)
            ),
            
          ],
        ),
      ),
    );
  }
}