import 'package:flutter/material.dart';
import '../../widgets/stat_card.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Users',
                  value: '156',
                  color: Colors.blue,
                  icon: Icons.people,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Active Trips',
                  value: '23',
                  color: Colors.green,
                  icon: Icons.directions_car,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending Approvals',
                  value: '12',
                  color: Colors.orange,
                  icon: Icons.pending_actions,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Revenue',
                  value: '₨45,670',
                  color: Colors.purple,
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}