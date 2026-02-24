import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class EmployeeDashboardContent extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? stats;

  const EmployeeDashboardContent({Key? key, required this.user, this.stats})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 44) / 2; // Calculate width for 2 columns

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Mode Info
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[800], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview Mode - Coming soon in future updates',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Stats
          Row(
            children: [
              _buildStatCard(
                'Total Trips',
                'Preview',
                Colors.orange,
                Icons.history,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Upcoming',
                'Preview',
                Colors.green,
                Icons.upcoming,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Notifications',
                'Preview',
                Colors.blue,
                Icons.notifications,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Recent Trips
          Text(
            'Recent Trips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Column(
            children: [
              _buildTripItem('Preview Trip 1', 'Route preview', 'Preview'),
              SizedBox(height: 8),
              _buildTripItem('Preview Trip 2', 'Route preview', 'Preview'),
              SizedBox(height: 8),
              _buildTripItem('Preview Trip 3', 'Route preview', 'Preview'),
            ],
          ),

          SizedBox(height: 24),

          // Quick Actions - 2x2 Grid
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Row 1
              SizedBox(
                width: itemWidth,
                child: _buildQuickAction(
                  'Trip History',
                  Icons.history,
                  Colors.purple,
                  'Preview',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildQuickAction(
                  'Favorite Routes',
                  Icons.favorite,
                  Colors.pink,
                  'Preview',
                ),
              ),
              // Row 2
              SizedBox(
                width: itemWidth,
                child: _buildQuickAction(
                  'Track Vehicle',
                  Icons.location_on,
                  Colors.blue,
                  'Preview',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildQuickAction(
                  'My Profile',
                  Icons.person,
                  Colors.teal,
                  'Preview',
                ),
              ),
            ],
          ),

          // Coming Soon Note
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Full employee dashboard features coming soon',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
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
                Text(
                  route,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(minWidth: 60),
            child: Chip(
              label: Text(status, style: TextStyle(fontSize: 11)),
              backgroundColor: Colors.yellow[100],
              labelStyle: TextStyle(color: Colors.yellow[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    String previewText,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              previewText,
              style: TextStyle(
                fontSize: 8,
                color: Colors.yellow[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
