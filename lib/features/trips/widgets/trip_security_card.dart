// lib/features/trips/widgets/trip_security_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/call_button.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/message_overlay.dart';

class TripSecurityCard<T extends TripCardModel> extends StatelessWidget {
  final T trip;
  final Widget? trailing;
  final bool showVehicleInfo;
  final bool showLocationInfo;
  final VoidCallback? onTap;

  const TripSecurityCard({
    Key? key,
    required this.trip,
    this.trailing,
    this.showVehicleInfo = true,
    this.showLocationInfo = false,
    this.onTap,
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
              _buildDriverInfo(context),
              const SizedBox(height: 8),
              _buildVehicleInfo(),
              const SizedBox(height: 8),
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
              const SizedBox(height: 4),

              _buildFooterSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    final status = trip.status.toLowerCase();

    return Column(
      children: [
        // Reading Button based on status
        if (status == 'approved') _buildStartReadingButton(context),

        if (status == 'finished') _buildEndReadingButton(context),

        // Reading Status (if readings exist)
        if (_hasReadings()) _buildReadingStatus(),

        SizedBox(height: 8)
      ],
    );
  }

  bool _hasReadings() {
      final has = trip.odometerReading?.startReading != null || trip.odometerReading?.endReading != null;
      return has;
  }

  Future<void> _recordOdometerReading(
    BuildContext context,
    String readingType,
  ) async {
    final readingController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Record ${readingType == 'start' ? 'Start' : 'End'} Odometer',
            style: const TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: readingController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Odometer Reading',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF9C80E)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter odometer reading';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final reading = double.parse(readingController.text);
                  try {
                    // Close the dialog first
                    if (dialogContext.mounted) Navigator.pop(dialogContext);

                    final response = await ApiService.recordOdometer(
                      trip.id,
                      reading,
                      readingType,
                    );

                    if (response['success'] == true) {
                      MessageOverlay.showSuccess(
                        context: context,
                        message: 'Odometer reading recorded successfully!',
                        position: OverlayPosition.top,
                        showBackgroundOverlay: true,
                        duration: const Duration(seconds: 3),
                        onComplete: () {
                          // You might want to trigger a refresh here
                        },
                      );
                    } else {
                      MessageOverlay.showError(
                        context: context,
                        message:
                            response['message'] ??
                            'Failed to record odometer reading',
                        position: OverlayPosition.top,
                        showBackgroundOverlay: true,
                        showOkButton: true,
                      );
                    }
                  } catch (e) {
                    if (dialogContext.mounted) Navigator.pop(dialogContext);

                    MessageOverlay.showError(
                      context: context,
                      message: 'Error: ${e.toString()}',
                      position: OverlayPosition.top,
                      showBackgroundOverlay: true,
                      showOkButton: true,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C80E),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartReadingButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: () => _recordOdometerReading(context, 'start'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Record Start Reading',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEndReadingButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: () => _recordOdometerReading(context, 'end'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Record End Reading',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReadingStatus() {
    final startReading = trip.odometerReading?.startReading;
    final endReading = trip.odometerReading?.endReading;
    final startRecordedBy = trip.odometerReading?.startReading;
    final endRecordedBy = trip.odometerReading?.endRecordedBy;

    return Column(
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Start Reading Column
            if (startReading != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Start:',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 2, 0, 0),
                      child: Text(
                        startReading.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (startRecordedBy != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 0, 0),
                        child: Text(
                          'By: $startRecordedBy',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            if (startReading != null && endReading != null)
              // Vertical divider
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[700]!.withOpacity(0.5),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

            // End Reading Column
            if (endReading != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stop, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'End:',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 2, 0, 0),
                      child: Text(
                        endReading.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (endRecordedBy != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 0, 0),
                        child: Text(
                          'By: $endRecordedBy',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),

        // Total distance if both readings exist
        if (startReading != null && endReading != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TOTAL : ${(endReading - startReading).toStringAsFixed(0)} km',
                  style: const TextStyle(
                    color: Color(0xFFF9C80E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
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
          ],
        ),

        // Badges Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trailing widget (if any)
            if (trailing != null) trailing!,

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getBadgeColor(trip.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getBadgeTest(trip.status),
                style: TextStyle(
                  color: getBadgeColor(trip.status),
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

  Widget _buildDriverInfo(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline_sharp, color: Colors.blue, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.driver?.name ?? 'Unknown',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              trip.driver?.phone ?? 'Unknown',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (trip.driver?.phone != null &&
            trip.driver?.phone != 'Unknown')
          CallButton(
            phoneNumber: trip.driver?.phone,
            contactName: trip.driver?.name,
            iconSize: 18,
            buttonSize: 36,
          ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return Row(
      children: [
        Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.blueGrey, size: 16),
            const SizedBox(width: 4),
            Text(
              trip.vehicleModel!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (trip.vehicleRegNo != null)
          Text(
            trip.vehicleRegNo!,
            style: TextStyle(color: Colors.amber[900], fontSize: 14),
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

  Color getBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'read':
        return Colors.purple;
      case 'ongoing':
        return Colors.blue;
      case 'finished':
        return Colors.red;
      case 'completed':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String getBadgeTest(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'NEEDS START READING';
      case 'read':
        return 'START READING TAKEN';
      case 'ongoing':
        return 'ONGOING';
      case 'finished':
        return 'NEEDS END READING';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

}
