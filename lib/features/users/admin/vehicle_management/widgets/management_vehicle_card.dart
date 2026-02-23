// lib/features/vehicles/widgets/management_vehicle_card.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicleType_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicle_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/color_generator.dart';

class ManagementVehicleCard extends StatefulWidget {
  final Vehicle vehicle;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDownloadQR;
  final List<VehicleType> vehicleTypes;
  final List<ShortUser> drivers;
  final List<String> fuelTypes;

  const ManagementVehicleCard({
    Key? key,
    required this.vehicle,
    required this.isExpanded,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDownloadQR,
    required this.vehicleTypes,
    required this.drivers,
    required this.fuelTypes,
  }) : super(key: key);

  @override
  _ManagementVehicleCardState createState() => _ManagementVehicleCardState();
}

class _ManagementVehicleCardState extends State<ManagementVehicleCard> {
  Uint8List _base64ToImage(String base64String) {
    try {
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      return base64.decode(base64String);
    } catch (e) {
      throw Exception('Invalid QR code data');
    }
  }

  String _getVehicleTypeName(int? typeId) {
    if (typeId == null) return 'Not specified';
    try {
      final type = widget.vehicleTypes.firstWhere((t) => t.id == typeId);
      return type.vehicleType;
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getDriverName(int? driverId) {
    if (driverId == null) return 'Not assigned';
    try {
      final driver = widget.drivers.firstWhere((d) => d.id == driverId);
      return driver.displayname;
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final backgroundColor = ColorGenerator.getRandomColor(vehicle.regNo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: widget.isExpanded
                  ? Border.all(color: Colors.grey.withOpacity(0.1), width: 2)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Vehicle Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Vehicle Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.regNo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.model ?? 'No Model'} • ${_getVehicleTypeName(vehicle.vehicleTypeId)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),

                    // Expand/Collapse Arrow
                    Transform.rotate(
                      angle: widget.isExpanded ? -1.5708 : 1.5708,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Expanded Details
                if (widget.isExpanded) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[800]),
                  const SizedBox(height: 16),

                  // Details Grid
                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.directions_car,
                        title: 'Model',
                        value: vehicle.model ?? 'Not specified',
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        icon: Icons.local_gas_station,
                        title: 'Fuel Type',
                        value: vehicle.fuelType ?? 'Not specified',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.people,
                        title: 'Seating Capacity',
                        value: '${vehicle.seatingCapacity}',
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        icon: Icons.speed,
                        title: 'Odometer',
                        value: '${vehicle.odometerLastReading} km',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.person,
                        title: 'Primary Driver',
                        value: _getDriverName(vehicle.assignedDriverPrimaryId),
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        icon: Icons.person_outline,
                        title: 'Secondary Driver',
                        value: _getDriverName(
                          vehicle.assignedDriverSecondaryId,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.circle,
                        title: 'Status',
                        value: vehicle.isActive ? 'Active' : 'Inactive',
                        valueColor: vehicle.isActive
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        icon: Icons.category,
                        title: 'Vehicle Type',
                        value: _getVehicleTypeName(vehicle.vehicleTypeId),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: Colors.grey[800]),
                  const SizedBox(height: 16),

                  // QR Code Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle QR Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: Column(
                          children: [
                            if (vehicle.qrCode != null &&
                                vehicle.qrCode!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                child: Column(
                                  children: [
                                    Image.memory(
                                      _base64ToImage(vehicle.qrCode!),
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Scan this QR code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 40,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No QR Code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            if (vehicle.qrCode != null &&
                                vehicle.qrCode!.isNotEmpty)
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9C80E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: widget.onDownloadQR,
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.download,
                                            color: Colors.black,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Download QR Code',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      // Edit Button
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9C80E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: widget.onEdit,
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Delete Button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: widget.onDelete,
                            child: const Center(
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
