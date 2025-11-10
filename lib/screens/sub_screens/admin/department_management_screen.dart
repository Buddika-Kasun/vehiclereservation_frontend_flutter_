// screens/admin/department_management_screen.dart
import 'package:flutter/material.dart';

class DepartmentManagementScreen extends StatelessWidget {
  const DepartmentManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Department Management'),
      ),
      body: Center(
        child: Text(
          'Department Management Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}