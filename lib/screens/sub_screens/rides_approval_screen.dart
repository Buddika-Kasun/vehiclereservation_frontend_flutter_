import 'package:flutter/material.dart';

class RidesApprovalScreen extends StatelessWidget {

  const RidesApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              " Rides Approval Screen", 
              style: TextStyle(color: Colors.white, fontSize: 24)
            ),
            
          ],
        ),
      ),
    );
  }
}