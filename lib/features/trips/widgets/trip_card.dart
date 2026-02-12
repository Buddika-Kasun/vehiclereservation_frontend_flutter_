// lib/features/trips/widgets/trip_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';

class TripCard<T extends TripCardModel> extends StatelessWidget {
  final T trip;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showVehicleInfo;
  final bool showLocationInfo;
  final bool showScheduleInfo;

  const TripCard({
    Key? key,
    required this.trip,
    required this.onTap,
    this.trailing,
    this.showVehicleInfo = true,
    this.showLocationInfo = true,
    this.showScheduleInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildRequesterInfo(),
              const SizedBox(height: 4),
              _buildDateTimeRow(),
              if (showLocationInfo) ...[
                if (trip.startLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildLocationRow(
                    trip.startLocation!,
                    'Start',
                    Icons.location_on,
                    Colors.green[400]!,
                  ),
                ],
                if (trip.endLocation != null) ...[
                  const SizedBox(height: 2),
                  _buildLocationRow(
                    trip.endLocation!,
                    'End',
                    Icons.location_on,
                    Colors.red[400]!,
                  ),
                ],
              ],
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trip #${trip.id}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            if (trailing != null) trailing!,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(trip.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trip.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(trip.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  */
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Trip ID
        Text(
          'Trip #${trip.id}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Badges Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scheduled Badge - check trip.isScheduled
            if (showScheduleInfo && trip.isScheduled == true)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.repeat, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text(
                      'Scheduled',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Instance Badge - check trip.isInstance
            if (showScheduleInfo && trip.isInstance == true)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_note,
                      size: 12,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Instance',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Trailing widget (if any)
            if (trailing != null) trailing!,

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(trip.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trip.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(trip.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequesterInfo() {
    return Row(
      children: [
        const Icon(Icons.person_outline_sharp, color: Colors.blue, size: 16),
        const SizedBox(width: 6),
        Text(
          trip.requesterName,
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
        const Spacer(),
        if (showVehicleInfo && trip.vehicleModel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.vehicleModel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trip.vehicleRegNo != null)
                Text(
                  trip.vehicleRegNo!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
            ],
          ),
        
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Text(
          trip.formatDate(),
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
        const SizedBox(width: 24),
        const Icon(Icons.access_time, color: Colors.grey, size: 16),
        const SizedBox(width: 6),
        Text(
          trip.formatTime(),
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationRow(
    String location,
    String label,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Click for full details',
            style: TextStyle(color: Color(0xFFF9C80E), fontSize: 14),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFF9C80E),
            size: 16,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.grey[700]!;
      case 'canceled':
        return Colors.red;
      case 'rejected':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

}
