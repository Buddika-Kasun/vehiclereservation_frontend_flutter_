import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class AdminDashboardContent extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? stats;

  const AdminDashboardContent({Key? key, required this.user, this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Overview Cards
          Row(
            children: [
              _buildSystemCard(
                'Total Users',
                '${stats?['totalUsers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              SizedBox(width: 12),
              _buildSystemCard(
                'Active Vehicles',
                '${stats?['activeVehicles'] ?? 0}',
                Icons.directions_car,
                Colors.green,
              ),
              SizedBox(width: 12),
              _buildSystemCard(
                'Pending Trips',
                '${stats?['totalTripsToday'] ?? 0}', // Adjusting label to match backend
                Icons.pending_actions,
                Colors.orange,
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // System Health
          Text(
            'System Health',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildHealthItem('Server Status', 'Online', Colors.green),
                SizedBox(height: 12),
                _buildHealthItem('Database', 'Healthy', Colors.green),
                SizedBox(height: 12),
                _buildHealthItem('API Response', 'Normal', Colors.green),
                SizedBox(height: 12),
                _buildHealthItem('Storage', '85% used', Colors.orange),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Quick Admin Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildAdminAction('Manage Users', Icons.person_add, Colors.blue, () {}),
              _buildAdminAction('Manage Vehicles', Icons.directions_car, Colors.green, () {}),
              _buildAdminAction('Manage Drivers', Icons.people_alt, Colors.purple, () {}),
              _buildAdminAction('System Settings', Icons.settings, Colors.orange, () {}),
              _buildAdminAction('View Reports', Icons.analytics, Colors.red, () {}),
              _buildAdminAction('Backup Data', Icons.backup, Colors.teal, () {}),
              _buildAdminAction('Audit Logs', Icons.list_alt, Colors.indigo, () {}),
              _buildAdminAction('User Roles', Icons.security, Colors.brown, () {}),
              _buildAdminAction('Maintenance', Icons.build, Colors.cyan, () {}),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Recent Activity
          Text(
            'Recent System Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildActivityItem('New vehicle registered', '10:45 AM', Icons.directions_car),
          _buildActivityItem('User "John Doe" created trip', '10:30 AM', Icons.add),
          _buildActivityItem('System backup completed', '09:15 AM', Icons.cloud_done),
          _buildActivityItem('Security alert resolved', 'Yesterday', Icons.security),
          _buildActivityItem('Database optimized', '2 days ago', Icons.storage),
        ],
      ),
    );
  }

  Widget _buildSystemCard(String title, String value, IconData icon, Color color) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Row 1: Icon
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Row 2: Value (Large number)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          SizedBox(height: 8),
          
          // Row 3: Title
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}
  Widget _buildHealthItem(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String description, String time, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
