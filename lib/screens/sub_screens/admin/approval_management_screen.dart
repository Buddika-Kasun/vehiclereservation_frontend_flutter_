// screens/admin/approval_management_screen.dart
import 'package:flutter/material.dart';

class ApprovalManagementScreen extends StatelessWidget {
  const ApprovalManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approval Management'),
      ),
      body: Center(
        child: Text(
          'Approval Management Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}