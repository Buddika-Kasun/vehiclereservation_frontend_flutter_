import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class SecurityDashboardContent extends StatelessWidget {
  final User? user;

  const SecurityDashboardContent({Key? key, required this.user})
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
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.yellow[800], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview Mode - Coming soon in future updates',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.yellow[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Today's Stats
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow[400]!, Colors.yellow[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Scans',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Preview',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.security, color: Colors.black, size: 40),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildScanStat('Valid', 'Preview', Colors.green[400]!),
                    SizedBox(width: 16),
                    _buildScanStat('Invalid', 'Preview', Colors.red[400]!),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Recent Scans
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Scans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: Text('View All')),
            ],
          ),
          SizedBox(height: 12),
          Column(
            children: [
              _buildScanItem('Preview Scan 1', '---', 'Preview Vehicle', true),
              SizedBox(height: 8),
              _buildScanItem('Preview Scan 2', '---', 'Preview Vehicle', true),
              SizedBox(height: 8),
              _buildScanItem('Preview Scan 3', '---', 'Preview Vehicle', false),
            ],
          ),

          SizedBox(height: 20),

          // Gate Status
          Text(
            'Gate Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          // Fixed overflow with Expanded and ConstrainedBox
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 120),
                    child: _buildGateStatusCard(
                      'Main Gate',
                      'Preview',
                      Colors.green,
                      Icons.door_front_door,
                      'Preview mode',
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 120),
                    child: _buildGateStatusCard(
                      'Back Gate',
                      'Preview',
                      Colors.red,
                      Icons.door_back_door,
                      'Preview mode',
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Security Actions
          Text(
            'Security Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.95, // Fixed aspect ratio to prevent overflow
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildSecurityAction(
                'Manual Entry',
                Icons.keyboard,
                Colors.blue,
                'Preview',
              ),
              _buildSecurityAction(
                'View Logs',
                Icons.history,
                Colors.orange,
                'Preview',
              ),
              _buildSecurityAction(
                'Reports',
                Icons.bar_chart,
                Colors.green,
                'Preview',
              ),
              _buildSecurityAction(
                'Alerts',
                Icons.notifications,
                Colors.red,
                'Preview',
              ),
              _buildSecurityAction(
                'Gate Control',
                Icons.lock_open,
                Colors.purple,
                'Preview',
              ),
              _buildSecurityAction(
                'Blacklist',
                Icons.block,
                Colors.brown,
                'Preview',
              ),
            ],
          ),

          SizedBox(height: 20),

          // Security Checks
          Text(
            'Security Checks',
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
                _buildCheckItem('Vehicle Inspection', 'Preview', Colors.green),
                SizedBox(height: 12),
                _buildCheckItem(
                  'Driver Verification',
                  'Preview',
                  Colors.orange,
                ),
                SizedBox(height: 12),
                _buildCheckItem('Security Cameras', 'Preview', Colors.green),
                SizedBox(height: 12),
                _buildCheckItem('Alarm System', 'Preview', Colors.green),
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
                    'Full security dashboard features coming soon in future updates',
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

  Widget _buildScanStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
            SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanItem(
    String time,
    String plate,
    String vehicle,
    bool isValid,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isValid ? Colors.green[100]! : Colors.red[100]!,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isValid ? Colors.green[50] : Colors.red[50],
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '$plate • $vehicle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(minWidth: 60),
            child: Chip(
              label: Text(
                isValid ? 'Valid' : 'Invalid',
                style: TextStyle(fontSize: 11),
              ),
              backgroundColor: isValid ? Colors.green[100] : Colors.red[100],
              labelStyle: TextStyle(
                color: isValid ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateStatusCard(
    String gateName,
    String status,
    Color color,
    IconData icon,
    String lastScan,
  ) {
    return Container(
      height: 120,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  gateName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            lastScan,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAction(
    String label,
    IconData icon,
    Color color,
    String previewText,
  ) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
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

  Widget _buildCheckItem(String check, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            check,
            style: TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
