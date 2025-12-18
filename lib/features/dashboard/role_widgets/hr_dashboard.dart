import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class HrDashboardContent extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? stats;

  const HrDashboardContent({Key? key, required this.user, this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Approval Stats
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Pending Approvals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'You have ${stats?['pendingTripApprovals'] ?? 0} trip requests waiting for approval',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('Review Requests'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Approval Statistics
          Text(
            'Approval Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildApprovalStat('Active', '${stats?['departmentActiveTrips'] ?? 0}', Colors.blue),
              SizedBox(width: 12),
              _buildApprovalStat('Total Users', '${stats?['departmentTotalUsers'] ?? 0}', Colors.green),
              SizedBox(width: 12),
              _buildApprovalStat('Pending', '${stats?['pendingTripApprovals'] ?? 0}', Colors.orange),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Recent Approvals
          Text(
            'Recent Approvals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildApprovalItem('John Doe', 'Colombo → Kandy', 'Approved', '10:30 AM'),
          _buildApprovalItem('Jane Smith', 'Galle → Colombo', 'Rejected', 'Yesterday'),
          _buildApprovalItem('Bob Wilson', 'Colombo → Negombo', 'Approved', '2 days ago'),
          _buildApprovalItem('Alice Johnson', 'Kandy → Galle', 'Pending', 'Pending'),
          
          SizedBox(height: 20),
          
          // Quick Filters
          Text(
            'Quick Filters',
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
              _buildFilterChip('Pending Review', Icons.pending),
              _buildFilterChip('Urgent', Icons.warning),
              _buildFilterChip('High Cost', Icons.attach_money),
              _buildFilterChip('Overtime', Icons.access_time),
              _buildFilterChip('Weekend Trips', Icons.weekend),
              _buildFilterChip('Long Distance', Icons.place),
            ],
          ),
          
          SizedBox(height: 20),
          
          // HR Actions
          Text(
            'HR Actions',
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
              _buildHrAction('Budget Reports', Icons.pie_chart, Colors.blue, () {}),
              _buildHrAction('Employee Trips', Icons.people, Colors.green, () {}),
              _buildHrAction('Cost Analysis', Icons.analytics, Colors.purple, () {}),
              _buildHrAction('Policy Rules', Icons.rule, Colors.orange, () {}),
              _buildHrAction('Travel History', Icons.history, Colors.teal, () {}),
              _buildHrAction('Department Stats', Icons.business, Colors.red, () {}),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Approval Queue
          Text(
            'Approval Queue',
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
                _buildQueueItem('Trip #1234', 'High Priority', 'Over budget limit', Colors.red),
                SizedBox(height: 12),
                _buildQueueItem('Trip #1235', 'Medium Priority', 'Weekend travel', Colors.orange),
                SizedBox(height: 12),
                _buildQueueItem('Trip #1236', 'Low Priority', 'Regular trip', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
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

  Widget _buildApprovalItem(String employee, String route, String status, String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getStatusColor(status).withOpacity(0.2),
            child: Text(
              employee[0],
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  route,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Chip(
                label: Text(status),
                backgroundColor: _getStatusColor(status).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Text(label),
      //icon: Icon(icon, size: 16),
      onSelected: (bool value) {},
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildHrAction(String label, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _buildQueueItem(String tripId, String priority, String reason, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tripId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
