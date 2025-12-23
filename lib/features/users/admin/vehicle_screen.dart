import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/optional_permission_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicle_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/constant.dart';

class VehicleScreen extends StatefulWidget {
  final User user;

  const VehicleScreen({Key? key, required this.user}) : super(key: key);

  @override
  _VehicleScreenState createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  @override
  String get namespace => 'vehicles';
  List<Vehicle> _primaryVehicles = [];
  List<Vehicle> _secondaryVehicles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  // Use separate expanded indices for primary and secondary vehicles
  int? _expandedPrimaryIndex;
  int? _expandedSecondaryIndex;

  @override
  void initState() {
    super.initState();
    _loadDriverVehicles();
  }

  List<Vehicle> _safeMapToVehicles(List<dynamic> data) {
    try {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return Vehicle.fromJson(item);
        } else if (item is Vehicle) {
          return item;
        } else {
          print('Unexpected vehicle data type: ${item.runtimeType}');
          return Vehicle(
            id: 0,
            regNo: 'Unknown',
            model: 'Unknown Model',
            isActive: false,
            seatingCapacity: 0,
            odometerLastReading: 0.0,
          );
        }
      }).toList();
    } catch (e) {
      print('Error mapping vehicle data: $e');
      return [];
    }
  }

  Future<void> _loadDriverVehicles() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final driverId = widget.user.id;

      final response = await ApiService.getDriverVehicles(driverId);
      
      if (response['success'] == true) {
        final primaryData = response['data']['primaryVehicles'] ?? [];
        final secondaryData = response['data']['secondaryVehicles'] ?? [];
        
        final primaryVehicles = _safeMapToVehicles(primaryData);
        final secondaryVehicles= _safeMapToVehicles(secondaryData);
        setState(() {
          _primaryVehicles = primaryVehicles;
          _secondaryVehicles = secondaryVehicles;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load vehicles');
      }
    } catch (e) {
      print('Error loading driver vehicles: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Helper method to check if a vehicle is expanded
  bool _isVehicleExpanded(int index, String assignmentType) {
    if (assignmentType == 'primary') {
      return _expandedPrimaryIndex == index;
    } else {
      return _expandedSecondaryIndex == index;
    }
  }

  // Helper method to handle vehicle tap
  void _handleVehicleTap(int index, String assignmentType) {
    setState(() {
      if (assignmentType == 'primary') {
        _expandedPrimaryIndex = _expandedPrimaryIndex == index ? null : index;
        // Collapse any expanded secondary vehicle
        _expandedSecondaryIndex = null;
      } else {
        _expandedSecondaryIndex = _expandedSecondaryIndex == index ? null : index;
        // Collapse any expanded primary vehicle
        _expandedPrimaryIndex = null;
      }
    });
  }

  Future<void> _downloadQRCode(String regNo, String? qrCodeBase64) async {
    if (qrCodeBase64 == null || qrCodeBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No QR code available for download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
            children: [
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

      // DIRECT PERMISSION REQUEST - No intermediate dialog
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
          SnackBar(
            content: Text('Permission denied. Cannot download QR code.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Convert base64 to image bytes
      final bytes = _base64ToImage(qrCodeBase64);

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${regNo}_qrcode_$timestamp.png';

      // Save to gallery using ImageGallerySaverPlus
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: fileName,
        quality: 100,
      );

      Navigator.pop(context);

      if (result['isSuccess'] == true) {
        // Success dialog
        _showSuccessDialog(
          title: 'QR Code Saved!',
          message: 'QR code has been saved to your device gallery.',
          fileName: fileName,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  // Helper method to show success dialog
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
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 10),
            Text(
              'File: $fileName',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 15),
            Text(
              'You can find it in your device gallery.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          /*
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Optional: Open gallery app
              // openGalleryApp();
            },
            child: Text('View in Gallery'),
          ),
          */
        ],
      ),
    );
  }
  
  IconData _getVehicleIcon(String? vehicleType) {
    if (vehicleType == null) return Icons.directions_car;
    switch (vehicleType.toLowerCase()) {
      case 'sedan': return Icons.directions_car;
      case 'suv': return Icons.airport_shuttle;
      case 'truck': return Icons.local_shipping;
      case 'van': return Icons.airport_shuttle;
      case 'bus': return Icons.directions_bus;
      case 'motorcycle': return Icons.motorcycle;
      case 'pickup': return Icons.local_shipping;
      case 'minivan': return Icons.airport_shuttle;
      default: return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, 0), 
          child: Text(
            (widget.user.role == UserRole.sysadmin)
                ? 'All Vehicles'
                : 'My Vehicles',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildErrorWidget()
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadDriverVehicles,
      child: CustomScrollView(
        slivers: [
          // Primary Vehicles Section
          if (_primaryVehicles.isNotEmpty) ...[
            _buildSectionHeader(
              (widget.user.role == UserRole.sysadmin) 
              ? 'Vehicles'
              : 'Primary Assigned Vehicles', _primaryVehicles.length),
            _buildVehiclesList(_primaryVehicles, 'primary'),
            // Add gap between sections
            SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],

          // Secondary Vehicles Section
          if (_secondaryVehicles.isNotEmpty) ...[
            _buildSectionHeader('Secondary Assigned Vehicles', _secondaryVehicles.length),
            _buildVehiclesList(_secondaryVehicles, 'secondary'),
          ],

          // Empty State
          if (_primaryVehicles.isEmpty && _secondaryVehicles.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildVehiclesList(List<Vehicle> vehicles, String assignmentType) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final vehicle = vehicles[index];
          final isExpanded = _isVehicleExpanded(index, assignmentType);
          final isPrimary = assignmentType == 'primary';
          
          return Container(
            margin: EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _handleVehicleTap(index, assignmentType);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorGenerator.getRandomColor(vehicle.regNo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isExpanded 
                        ? Border.all(color: ColorGenerator.getRandomColor(vehicle.regNo).withOpacity(0.2), width: 2)
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
                              color: ColorGenerator.getRandomColor(vehicle.regNo),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                _getVehicleIcon(vehicle.vehicleType),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          
                          // Vehicle Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.regNo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${vehicle.model ?? 'No Model'} • ${vehicle.vehicleType ?? 'No Type'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Expand/Collapse Arrow
                          Transform.rotate(
                            angle: isExpanded ? -1.5708 : 1.5708,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      // Expanded Details
                      if (isExpanded) ...[
                        SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        
                        // Details Grid - Row 1
                        Row(
                          children: [
                            _buildDetailItem(
                              icon: Icons.directions_car,
                              title: 'Model',
                              value: vehicle.model ?? 'Not specified',
                            ),
                            SizedBox(width: 24),
                            _buildDetailItem(
                              icon: Icons.local_gas_station,
                              title: 'Fuel Type',
                              value: vehicle.fuelType ?? 'Not specified',
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Details Grid - Row 2
                        Row(
                          children: [
                            _buildDetailItem(
                              icon: Icons.people,
                              title: 'Seating Capacity',
                              value: '${vehicle.seatingCapacity}',
                            ),
                            SizedBox(width: 24),
                            _buildDetailItem(
                              icon: Icons.speed,
                              title: 'Odometer',
                              value: '${vehicle.odometerLastReading} km',
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Details Grid - Row 3
                        Row(
                          children: [
                            _buildDetailItem(
                              icon: Icons.person,
                              title: isPrimary ? 'Driver' : 'Primary Driver',
                              value: vehicle.assignedDriverPrimaryName ?? 'Not assigned',
                            ),
                            SizedBox(width: 24),
                            _buildDetailItem(
                              icon: Icons.circle,
                              title: 'Status',
                              value: vehicle.isActive ? 'Active' : 'Inactive',
                              valueColor: vehicle.isActive ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),

                        if (!isPrimary) ...[
                          SizedBox(height: 16),
                          Row(
                            children: [
                              _buildDetailItem(
                                icon: Icons.person_outline,
                                title: 'Co-Driver',
                                value: vehicle.assignedDriverSecondaryName ?? 'Not assigned',
                              ),
                            ],
                          ),
                        ],
                        
                        SizedBox(height: 20),
                        Divider(height: 1, color: Colors.grey[300]),
                        SizedBox(height: 16),

                        // QR Code Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle QR Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                children: [
                                  // Real QR Code Display
                                  if (vehicle.qrCode != null && vehicle.qrCode!.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      child: Column(
                                        children: [
                                          Image.memory(
                                            _base64ToImage(vehicle.qrCode!),
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          ),
                                          SizedBox(height: 8),
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_2, size: 40, color: Colors.grey[600]),
                                          SizedBox(height: 8),
                                          Text(
                                            'No QR Code',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Download Button
                                  if (vehicle.qrCode != null && vehicle.qrCode!.isNotEmpty)
                                    Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => _downloadQRCode(vehicle.regNo, vehicle.qrCode),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.download, color: Colors.white, size: 18),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Download QR Code',
                                                  style: TextStyle(
                                                    color: Colors.white,
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
        },
        childCount: vehicles.length,
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.black87,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  SliverFillRemaining _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No Vehicles Assigned',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You don\'t have any vehicles assigned to you yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading your vehicles...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error Loading Vehicles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDriverVehicles,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
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
}
