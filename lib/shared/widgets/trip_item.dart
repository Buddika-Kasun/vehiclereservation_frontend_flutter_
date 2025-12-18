import 'package:flutter/material.dart';

class TripItem extends StatelessWidget {
  final String vehicle;
  final String duration;
  final String rating;
  final String details;
  final String? location;

  const TripItem({
    Key? key,
    required this.vehicle,
    required this.duration,
    required this.rating,
    required this.details,
    this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(Icons.directions_car, color: Colors.blue),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(duration),
                    SizedBox(width: 16),
                    Icon(Icons.star, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(rating),
                  ],
                ),
                SizedBox(height: 4),
                if (location != null) ...[
                  Text(
                    location!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                ],
                Text(
                  details,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
