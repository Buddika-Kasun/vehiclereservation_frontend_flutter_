// lib/features/trips/widgets/trip_header.dart
import 'package:flutter/material.dart';

class TripHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showConnectionStatus;
  final bool isConnected;
  final VoidCallback? onRefresh;

  const TripHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.showConnectionStatus = false,
    this.isConnected = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (showConnectionStatus)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? Colors.green : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? Colors.green : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              const Spacer(),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFFF9C80E)),
                  onPressed: onRefresh,
                ),
            ],
          )
        ],
      ),
    );
  }

}
