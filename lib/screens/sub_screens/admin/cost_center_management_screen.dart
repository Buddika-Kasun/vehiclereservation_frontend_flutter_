// screens/admin/cost_center_management_screen.dart
import 'package:flutter/material.dart';

class CostCenterManagementScreen extends StatelessWidget {
  const CostCenterManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cost Center Management'),
      ),
      body: Center(
        child: Text(
          'Cost Center Management Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}