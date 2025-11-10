// screens/admin/vehicle_management_screen.dart
import 'package:flutter/material.dart';

class VehicleManagementScreen extends StatelessWidget {
  const VehicleManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Management'),
      ),
      body: Center(
        child: Text(
          'Vehicle Management Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}