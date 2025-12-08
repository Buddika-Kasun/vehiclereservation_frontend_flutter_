import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';

class SecurityDashboardContent extends StatelessWidget {
  final User? user;

  const SecurityDashboardContent({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '47',
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
                    _buildScanStat('Valid', '45', Colors.green[400]!),
                    SizedBox(width: 16),
                    _buildScanStat('Invalid', '2', Colors.red[400]!),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildScanItem('10:15 AM', 'ABC-1234', 'Toyota Hiace', true),
          _buildScanItem('09:45 AM', 'DEF-5678', 'Mitsubishi Lancer', true),
          _buildScanItem('09:30 AM', 'GHI-9012', 'Nissan Van', true),
          _buildScanItem('08:30 AM', 'JKL-3456', 'Toyota Prius', false),
          
          SizedBox(height: 20),
          
          // Gate Status
          Text(
            'Gate Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGateStatusCard(
                  'Main Gate',
                  'OPEN',
                  Colors.green,
                  Icons.door_front_door,
                  'Last scan: 10:30 AM',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildGateStatusCard(
                  'Back Gate',
                  'CLOSED',
                  Colors.red,
                  Icons.door_back_door,
                  'Last scan: 09:15 AM',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Security Actions
          Text(
            'Security Actions',
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
              _buildSecurityAction('Manual Entry', Icons.keyboard, Colors.blue, () {}),
              _buildSecurityAction('View Logs', Icons.history, Colors.orange, () {}),
              _buildSecurityAction('Reports', Icons.bar_chart, Colors.green, () {}),
              _buildSecurityAction('Alerts', Icons.notifications, Colors.red, () {}),
              _buildSecurityAction('Gate Control', Icons.lock_open, Colors.purple, () {}),
              _buildSecurityAction('Blacklist', Icons.block, Colors.brown, () {}),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Security Checks
          Text(
            'Security Checks',
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
                _buildCheckItem('Vehicle Inspection', 'Completed', Colors.green),
                SizedBox(height: 12),
                _buildCheckItem('Driver Verification', 'Pending', Colors.orange),
                SizedBox(height: 12),
                _buildCheckItem('Security Cameras', 'Online', Colors.green),
                SizedBox(height: 12),
                _buildCheckItem('Alarm System', 'Armed', Colors.green),
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
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanItem(String time, String plate, String vehicle, bool isValid) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$plate • $vehicle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(isValid ? 'Valid' : 'Invalid'),
            backgroundColor: isValid ? Colors.green[100] : Colors.red[100],
            labelStyle: TextStyle(
              color: isValid ? Colors.green[800] : Colors.red[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateStatusCard(String gateName, String status, Color color, IconData icon, String lastScan) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                gateName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
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
            ],
          ),
          SizedBox(height: 8),
          Text(
            lastScan,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAction(String label, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _buildCheckItem(String check, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(check, style: TextStyle(fontWeight: FontWeight.w500)),
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
}