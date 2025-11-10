// screens/user_creations_screen.dart
import 'package:flutter/material.dart';

class UserCreationsScreen extends StatelessWidget {
  const UserCreationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Creations'),
      ),
      body: Center(
        child: Text(
          'User Creations Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}