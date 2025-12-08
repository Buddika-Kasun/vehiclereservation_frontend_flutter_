import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';

class EmployeeDashboardContent extends StatelessWidget {
  final User? user;

  const EmployeeDashboardContent({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              _buildStatCard(
                'Pending Trips',
                '3',
                Colors.orange,
                Icons.pending_actions,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Approved',
                '5',
                Colors.green,
                Icons.check_circle,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Completed',
                '12',
                Colors.blue,
                Icons.done_all,
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Recent Trips
          Text(
            'Recent Trips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildTripItem('Today', 'Colombo → Kandy', 'Approved'),
          _buildTripItem('Yesterday', 'Galle → Colombo', 'Completed'),
          _buildTripItem('2 days ago', 'Colombo → Negombo', 'Pending'),
          
          SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickAction('Trip History', Icons.history, Colors.purple),
              _buildQuickAction('Favorite Routes', Icons.favorite, Colors.pink),
              _buildQuickAction('Track Vehicle', Icons.location_on, Colors.blue),
              _buildQuickAction('My Profile', Icons.person, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripItem(String date, String route, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_car, size: 16),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Chip(
            label: Text(status),
            backgroundColor: _getStatusColor(status).withOpacity(0.2),
            labelStyle: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}