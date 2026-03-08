// lib/features/vehicles/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/optional_permission_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicle_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/constant.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/check_list_screen.dart';

class VehicleCard extends StatefulWidget {
  final Vehicle vehicle;
  final bool isExpanded;
  final VoidCallback onTap;
  final User user;
  final String assignmentType;
  final VoidCallback? onChecklistComplete;

  const VehicleCard({
    Key? key,
    required this.vehicle,
    required this.isExpanded,
    required this.onTap,
    required this.user,
    required this.assignmentType,
    this.onChecklistComplete,
  }) : super(key: key);

  @override
  _VehicleCardState createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  bool _isDownloading = false;

  Future<void> _downloadQRCode() async {
    if (_isDownloading) return;

    final qrCodeBase64 = widget.vehicle.qrCode;
    if (qrCodeBase64 == null || qrCodeBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR code available for download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Preparing QR Code...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );

      final hasPermission =
          await OptionalPermissionManager.requestDownloadPermission(
            context: context,
            rationaleMessage:
                'Storage access is required to save QR codes to your device gallery.',
            isMedia: true,
          );

      if (!hasPermission) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot download QR code.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      // Convert base64 to image bytes
      final bytes = _base64ToImage(qrCodeBase64);

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.vehicle.regNo}_qrcode_$timestamp.png';

      // Save to gallery using ImageGallerySaverPlus
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: fileName,
        quality: 100,
      );

      Navigator.pop(context);

      if (result['isSuccess'] == true) {
        _showSuccessDialog(
          title: 'QR Code Saved!',
          message: 'QR code has been saved to your device gallery.',
          fileName: fileName,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save QR code to gallery'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download QR code: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required String fileName,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 10),
            Text(
              'File: $fileName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'You can find it in your device gallery.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
    final isPrimary = widget.assignmentType == 'primary';
    final backgroundColor = ColorGenerator.getRandomColor(vehicle.regNo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey[900], // Dark background
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
              color: Colors.grey[900], // Dark background
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
                            '${vehicle.model ?? 'No Model'} • ${vehicle.vehicleType ?? 'No Type'}',
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

                  // Details Grid - Row 1
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

                  // Details Grid - Row 2
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

                  // Details Grid - Row 3
                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.person,
                        title: isPrimary ? 'Driver' : 'Primary Driver',
                        value:
                            vehicle.assignedDriverPrimaryName ?? 'Not assigned',
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        icon: Icons.circle,
                        title: 'Status',
                        value: vehicle.isActive ? 'Active' : 'Inactive',
                        valueColor: vehicle.isActive
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details Grid - Row 4
                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.list,
                        title: 'Today Checking',
                        value: vehicle.todayChecked == true
                            ? 'Checked'
                            : 'Not Checked',
                        valueColor: vehicle.todayChecked == true
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ],
                  ),

                  if (!isPrimary) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDetailItem(
                          icon: Icons.person_outline,
                          title: 'Co-Driver',
                          value:
                              vehicle.assignedDriverSecondaryName ??
                              'Not assigned',
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  Divider(height: 1, color: Colors.grey[800]),
                  const SizedBox(height: 8),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(0xFFF9C80E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                // Navigate to checklist screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChecklistScreen(
                                      vehicleId: vehicle.id.toString(),
                                      vehicleRegNo: vehicle.regNo,
                                      userId: widget.user.id.toString(),
                                      userRole: widget.user.role.name,
                                      userName: widget.user.displayname,
                                    ),
                                  ),
                                ).then((result) {
                                  // This runs AFTER navigation is complete
                                  if (mounted && result == true) {
                                    widget.onChecklistComplete?.call();
                                  }
                                });
                              },
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.checklist,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Go to Checklist',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
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
                            // Real QR Code Display
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

                            // Download Button
                            if (vehicle.qrCode != null &&
                                vehicle.qrCode!.isNotEmpty)
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF9C80E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _isDownloading
                                        ? null
                                        : _downloadQRCode,
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isDownloading
                                                ? Icons.hourglass_empty
                                                : Icons.download,
                                            color: Colors.black,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isDownloading
                                                ? 'Downloading...'
                                                : 'Download QR Code',
                                            style: const TextStyle(
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
