import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class HrDashboardContent extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? stats;

  const HrDashboardContent({Key? key, required this.user, this.stats})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[800], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview Mode - Coming soon in future updates',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                  'Approval features are under development',
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
                      Text('Preview Feature'),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildApprovalStat('Active', 'Preview', Colors.blue),
              SizedBox(width: 12),
              _buildApprovalStat('Total Users', 'Preview', Colors.green),
              SizedBox(width: 12),
              _buildApprovalStat('Pending', 'Preview', Colors.orange),
            ],
          ),

          SizedBox(height: 20),

          // Recent Approvals
          Text(
            'Recent Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Column(
            children: [
              _buildApprovalItem(
                'Preview User 1',
                'Route preview',
                'Preview',
                'Time',
              ),
              SizedBox(height: 8),
              _buildApprovalItem(
                'Preview User 2',
                'Route preview',
                'Preview',
                'Time',
              ),
              SizedBox(height: 8),
              _buildApprovalItem(
                'Preview User 3',
                'Route preview',
                'Preview',
                'Time',
              ),
            ],
          ),

          SizedBox(height: 20),

          // Quick Filters
          Text(
            'Quick Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterChip('Pending Review', Icons.pending, 'Preview'),
              _buildFilterChip('Urgent', Icons.warning, 'Preview'),
              _buildFilterChip('High Cost', Icons.attach_money, 'Preview'),
              _buildFilterChip('Overtime', Icons.access_time, 'Preview'),
              _buildFilterChip('Weekend Trips', Icons.weekend, 'Preview'),
              _buildFilterChip('Long Distance', Icons.place, 'Preview'),
            ],
          ),

          SizedBox(height: 20),

          // HR Actions
          Text(
            'HR Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              _buildHrAction(
                'Budget Reports',
                Icons.pie_chart,
                Colors.blue,
                'Preview',
              ),
              _buildHrAction(
                'Employee Trips',
                Icons.people,
                Colors.green,
                'Preview',
              ),
              _buildHrAction(
                'Cost Analysis',
                Icons.analytics,
                Colors.purple,
                'Preview',
              ),
              _buildHrAction(
                'Policy Rules',
                Icons.rule,
                Colors.orange,
                'Preview',
              ),
              _buildHrAction(
                'Travel History',
                Icons.history,
                Colors.teal,
                'Preview',
              ),
              _buildHrAction(
                'Department Stats',
                Icons.business,
                Colors.red,
                'Preview',
              ),
            ],
          ),

          SizedBox(height: 20),

          // Approval Queue
          Text(
            'Approval Queue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                _buildQueueItem(
                  'Trip #---',
                  'Preview Priority',
                  'Preview reason',
                  Colors.yellow,
                ),
                SizedBox(height: 12),
                _buildQueueItem(
                  'Trip #---',
                  'Preview Priority',
                  'Preview reason',
                  Colors.yellow,
                ),
                SizedBox(height: 12),
                _buildQueueItem(
                  'Trip #---',
                  'Preview Priority',
                  'Preview reason',
                  Colors.yellow,
                ),
              ],
            ),
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
                    'Full HR dashboard features coming soon in future updates',
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

  Widget _buildApprovalItem(
    String employee,
    String route,
    String status,
    String time,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.yellow.withOpacity(0.2),
            child: Text(
              employee[0],
              style: TextStyle(
                color: Colors.yellow[800],
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  route,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Chip(
                label: Text(status),
                backgroundColor: Colors.yellow[100],
                labelStyle: TextStyle(
                  color: Colors.yellow[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, String previewText) {
    return FilterChip(
      label: Text(label),
      onSelected: (bool value) {},
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(fontSize: 11),
    );
  }

  Widget _buildHrAction(
    String label,
    IconData icon,
    Color color,
    String previewText,
  ) {
    return Container(
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

  Widget _buildQueueItem(
    String tripId,
    String priority,
    String reason,
    Color color,
  ) {
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
                Text(tripId, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
}
