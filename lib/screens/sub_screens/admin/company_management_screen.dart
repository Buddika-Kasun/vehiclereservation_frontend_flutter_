// screens/admin/company_management_screen.dart
import 'package:flutter/material.dart';

class CompanyManagementScreen extends StatelessWidget {
  const CompanyManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Company Management'),
      ),
      body: Center(
        child: Text(
          'Company Management Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}