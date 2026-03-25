// lib/features/trips/widgets/trip_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';

class TripCard<T extends TripCardModel> extends StatelessWidget {
  final T trip;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showVehicleInfo;
  final bool showLocationInfo;
  final bool showScheduleInfo;
  final bool showTripType;
  final bool showCreatedAt;
  final bool showConfirmAt;

  const TripCard({
    Key? key,
    required this.trip,
    required this.onTap,
    this.trailing,
    this.showVehicleInfo = true,
    this.showLocationInfo = true,
    this.showScheduleInfo = false,
    this.showTripType = false,
    this.showCreatedAt = false,
    this.showConfirmAt = false,
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
              if (showCreatedAt) ...[
                _buildCreatedAt(),
              ],
              if (showConfirmAt) ...[
                _buildConfirmAt(),
              ],
              _buildRequesterVehicleInfo(),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            // Trip user type
            if (showTripType && trip.tripUserType != null)
              Container(
                margin: const EdgeInsets.only(right: 2),
                padding: const EdgeInsets.symmetric(vertical: 2),
                width: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tripTypeColor(trip.tripUserType!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tripTypeLabel(trip.tripUserType!),
                  style: TextStyle(
                    color: tripTypeColor(trip.tripUserType!),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Trip ID
            Text(
              'Trip #${trip.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat,
                      size: 12,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Scheduled',
                      style: TextStyle(
                        color: Colors.blueAccent,
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
                  color: Colors.purpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_note,
                      size: 12,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Instance',
                      style: TextStyle(
                        color: Colors.purpleAccent,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(trip.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trip.status.toUpperCase(),
                style: TextStyle(
                  color: getStatusColor(trip.status),
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

  Widget _buildRequesterVehicleInfo() {
    return Row(
      children: [
        const Icon(Icons.person_outline_sharp, color: Colors.blue, size: 16),
        const SizedBox(width: 6),
        Text(
          trip.requesterName ?? 'Unknown',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (showVehicleInfo && trip.vehicleModel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    trip.vehicleModel == 'Unknown' ? 'N/A' : trip.vehicleModel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.directions_car,
                    color: Colors.blueGrey,
                    size: 16,
                  ),
                ],
              ),
              if (trip.vehicleRegNo != null)
                Text(
                  trip.vehicleRegNo == 'Unknown' ? 'N/A' : trip.vehicleRegNo!,
                  style: TextStyle(color: Colors.amber[900], fontSize: 12),
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

  Widget _buildCreatedAt() {
    return Row(
      children: [
        Icon(
          Icons.create,
          size: 16,
          color: trip.createdAt != null ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            trip.formatCreatedAt(),
            style: TextStyle(
              fontSize: 13,
              color: trip.createdAt != null ? Colors.blue : Colors.grey,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmAt() {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: trip.confirmAt != null ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            trip.formatConfirmAt(),
            style: TextStyle(
              fontSize: 13,
              color: trip.confirmAt != null ? Colors.green : Colors.grey,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

}
