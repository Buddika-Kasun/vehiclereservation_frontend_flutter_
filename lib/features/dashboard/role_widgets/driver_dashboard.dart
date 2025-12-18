import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class DriverDashboardContent extends StatelessWidget {
  final User? user;

  const DriverDashboardContent({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.red, size: 12),
                SizedBox(width: 12),
                Text('Status: Offline', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text('Last updated: 10:30 AM', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Today's Schedule
          Text(
            "Today's Schedule",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildScheduleItem('9:00 AM', 'Colombo Office', 'Kandy Office', 'Assigned'),
          _buildScheduleItem('2:00 PM', 'Kandy Office', 'Colombo Office', 'Pending'),
          
          SizedBox(height: 20),
          
          // Vehicle Info
          Text(
            'Assigned Vehicle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Toyota Hiace - ABC-1234', style: TextStyle(fontWeight: FontWeight.bold)),
                    Chip(label: Text('Available'), backgroundColor: Colors.green[100]),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVehicleStat('Fuel', '75%', Icons.local_gas_station),
                    _buildVehicleStat('KM', '125,400', Icons.speed),
                    _buildVehicleStat('Next Service', '500km', Icons.build),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String from, String to, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16),
          SizedBox(width: 8),
          Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: $from'),
                Text('To: $to'),
              ],
            ),
          ),
          Chip(
            label: Text(status),
            backgroundColor: status == 'Assigned' ? Colors.blue[100] : Colors.orange[100],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
