import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
//import 'dart:io';
//import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicleType_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicle_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/constant.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({Key? key}) : super(key: key);

  @override
  _VehicleManagementScreenState createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Vehicle> _vehicles = [];
  List<VehicleType> _vehicleTypes = [];
  List<ShortUser> _drivers = [];
  int? _expandedIndex;
  bool _isLoading = true;
  bool _hasCompany = false;
  bool _hasVehicleTypes = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Fuel type options
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    _checkCompanyAndLoadData();
  }

  Future<void> _checkCompanyAndLoadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // First check if company exists
      final companyResponse = await ApiService.getCompanyStatus();
      
      if (companyResponse['success'] == true) {
        setState(() {
          _hasCompany = companyResponse['data'] ?? false;
        });

        // Check if vehicle types exist
        final vehicleTypesResponse = await ApiService.getVehicleTypes();
        
        if (vehicleTypesResponse['success'] == true) {
          final List<dynamic> vehicleTypesData = vehicleTypesResponse['data']['costConfigurations'] ?? [];
          setState(() {
            _hasVehicleTypes = vehicleTypesData.isNotEmpty;
            _vehicleTypes = vehicleTypesData.map((data) => VehicleType.fromJson(data)).toList();
          });

          if (_hasCompany && _hasVehicleTypes) {
            // Load all data only if company and vehicle types exist
            await Future.wait([
              _loadVehicles(),
              _loadDrivers(),
            ]);
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          throw Exception(vehicleTypesResponse['message'] ?? 'Failed to check vehicle types');
        }
      } else {
        throw Exception(companyResponse['message'] ?? 'Failed to check company status');
      }
    } catch (e) {
      print('Error checking company: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final response = await ApiService.getVehicles();
      
      if (response['success'] == true) {
        final List<dynamic> vehiclesData = response['data']['vehicles'] ?? [];
        setState(() {
          _vehicles = vehiclesData.map((data) => Vehicle.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load vehicles');
      }
    } catch (e) {
      print('Error loading vehicles: $e');
      rethrow;
    }
  }

  Future<void> _loadDrivers() async {
    try {
      //final response = await ApiService.getUsers(); // filter with transport department
      final response = await ApiService.getUsersByRole('driver'); 

      if (response['success'] == true) {
        final List<dynamic> usersData = response['data']['users'] ?? [];
        setState(() {
          // Filter users who are drivers (you might need to adjust this based on your user roles)
          _drivers = usersData.map((data) => ShortUser.fromJson(data)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load drivers');
      }
    } catch (e) {
      print('Error loading drivers: $e');
      rethrow;
    }
  }

  Future<void> _createVehicle(Vehicle vehicle) async {
    try {
      final response = await ApiService.createVehicle(vehicle.toJson());
      
      if (response['success'] == true) {
        await _loadVehicles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle created successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create vehicle');
      }
    } catch (e) {
      print('Error creating vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create vehicle: $e')),
      );
      rethrow;
    }
  }

  Future<void> _updateVehicle(Vehicle vehicle) async {
    try {
      final response = await ApiService.updateVehicle(vehicle.id, vehicle.toJson());
      
      if (response['success'] == true) {
        await _loadVehicles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle updated successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update vehicle');
      }
    } catch (e) {
      print('Error updating vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vehicle: $e')),
      );
      rethrow;
    }
  }

  Future<void> _deleteVehicle(int id, int index) async {
    try {
      final response = await ApiService.deleteVehicle(id);
      
      if (response['success'] == true) {
        setState(() {
          _vehicles.removeAt(index);
          _expandedIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle deleted successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete vehicle');
      }
    } catch (e) {
      print('Error deleting vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete vehicle: $e')),
      );
      rethrow;
    }
  }

/*
  String _generateShortName(String regNo) {
    if (regNo.isEmpty) return 'VH';
    return regNo.length <= 4 ? regNo.toUpperCase() : regNo.substring(regNo.length - 4).toUpperCase();
  }
*/

  Future<void> _downloadQRCode(String regNo, String? qrCodeBase64) async {
    if (qrCodeBase64 == null || qrCodeBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No QR code available for download')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission is required to download QR code')),
        );
        return;
      }

      // Convert base64 to bytes
      final bytes = _base64ToImage(qrCodeBase64);
      
      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: '${regNo}_qrcode',
        quality: 100,
      );

      Navigator.pop(context); // Remove loading

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save QR code to gallery')),
        );
      }
      
    } catch (e) {
      Navigator.pop(context); // Remove loading in case of error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download QR code: $e')),
      );
    }
  }

  /* Download Qr code to folder android
  Future<void> _downloadQRCodeToDownloads(String regNo, String? qrCodeBase64) async {
    if (qrCodeBase64 == null || qrCodeBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No QR code available for download')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission is required')),
        );
        return;
      }

      // Convert base64 to bytes
      final bytes = _base64ToImage(qrCodeBase64);
      
      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }
      
      // Create file
      final file = File('${directory.path}/${regNo}_qrcode.png');
      await file.writeAsBytes(bytes);
      
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code saved to Downloads folder!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download QR code: $e')),
      );
    }
  }
  */

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
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildErrorWidget()
              : !_hasCompany || !_hasVehicleTypes
                  ? _buildRequirementsWidget()
                  : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Create New Button
        Padding(
          padding: EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showCreateVehicleDialog,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create New',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
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

        SizedBox(height: 8),
        
        // Available Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Available',
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
                  _vehicles.length.toString(),
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

        SizedBox(height: 16),

        // Vehicles List
        Expanded(
          child: _vehicles.isEmpty 
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      final isExpanded = _expandedIndex == index;
                      //final shortName = _generateShortName(vehicle.regNo);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              });
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
                                          title: 'Driver',
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
                                    
                                    SizedBox(height: 16),
                                    
                                    // Action Buttons
                                    Row(
                                      children: [
                                        // Edit Button
                                        Expanded(
                                          child: Container(
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.secondary.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () {
                                                  _showEditVehicleDialog(index, vehicle);
                                                },
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Edit Vehicle',
                                                        style: TextStyle(
                                                          color: AppColors.primary,
                                                          fontSize: 16,
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
                                        SizedBox(width: 12),
                                        
                                        // Delete Button
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () {
                                                _showDeleteConfirmation(index);
                                              },
                                              child: Center(
                                                child: Icon(Icons.delete, color: Colors.white, size: 20),
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
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No Vehicle Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your vehicle to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
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

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading...',
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
              'Error Loading Data',
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
              onPressed: _checkCompanyAndLoadData,
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

  Widget _buildRequirementsWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Requirements Missing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              !_hasCompany 
                  ? 'You need to create a company before managing vehicles.'
                  : 'You need to create vehicle types before managing vehicles.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            /*ElevatedButton.icon(
              onPressed: () {
                // Navigate to company or vehicle type creation screen
              },
              icon: Icon(!_hasCompany ? Icons.add_business : Icons.directions_car),
              label: Text(!_hasCompany ? 'Create Company' : 'Create Vehicle Types'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  void _showCreateVehicleDialog() {
  String regNo = '';
  String model = '';
  int? selectedVehicleType;
  String? selectedFuelType;
  int seatingCapacity = 4;
  int? selectedDriverPrimaryId;
  int? selectedDriverSecondaryId;
  double odometerLastReading = 0.0;
  bool isActive = true;
  bool _isSubmitting = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sticky Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'New Vehicle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Divider
              Container(height: 1, color: Colors.grey.shade800),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Registration No Field
                      TextField(
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Registration No *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.confirmation_number, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'e.g., CAB-1234',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                        onChanged: (value) => regNo = value,
                      ),
                      const SizedBox(height: 16),

                      // Model Field
                      TextField(
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Model',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.directions_car, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'e.g., Toyota Corolla',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                        onChanged: (value) => model = value,
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Type Dropdown
                      DropdownButtonFormField<int>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.category, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedVehicleType,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._vehicleTypes.map((type) {
                            return DropdownMenuItem(
                              value: type.id,
                              child: Text(type.vehicleType, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fuel Type Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Fuel Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.local_gas_station, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedFuelType,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._fuelTypes.map((fuel) {
                            return DropdownMenuItem(
                              value: fuel,
                              child: Text(fuel, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedFuelType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Seating Capacity Field
                      TextField(
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Seating Capacity',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.people, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'e.g., 5',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => seatingCapacity = int.tryParse(value) ?? 4,
                      ),
                      const SizedBox(height: 16),

                      // Assigned Driver Dropdown
                      DropdownButtonFormField<int>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Assigned Driver',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedDriverPrimaryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._drivers.map((driver) {
                            return DropdownMenuItem(
                              value: driver.id,
                              child: Text(driver.displayname, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDriverPrimaryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Co-Driver Dropdown
                      DropdownButtonFormField<int>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Co-Driver',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedDriverSecondaryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._drivers.map((driver) {
                            return DropdownMenuItem(
                              value: driver.id,
                              child: Text(driver.displayname, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDriverSecondaryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Odometer Reading Field
                      TextField(
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Last Odometer Reading',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.speed, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'e.g., 15000.5',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) => odometerLastReading = double.tryParse(value) ?? 0.0,
                      ),
                      const SizedBox(height: 8),

                      // Active/Inactive Toggle
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Active Vehicle",
                              style: TextStyle(color: Colors.white, fontSize: 16)
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isActive,
                                onChanged: (bool value) {
                                  setState(() {
                                    isActive = value;
                                  });
                                },
                                inactiveTrackColor: Colors.transparent,
                                inactiveThumbColor: Colors.yellow.shade600,
                                activeColor: Colors.yellow[600],
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Buttons Row
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade600, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.transparent,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isSubmitting ? null : () => Navigator.pop(context),
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Create Button
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isSubmitting ? [] : [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isSubmitting ? null : () async {
                                    if (regNo.isNotEmpty) {
                                      try {
                                        setState(() {
                                          _isSubmitting = true;
                                        });

                                        final newVehicle = Vehicle(
                                          id: 0,
                                          regNo: regNo,
                                          model: model.isEmpty ? null : model,
                                          fuelType: selectedFuelType,
                                          seatingCapacity: seatingCapacity,
                                          odometerLastReading: odometerLastReading,
                                          vehicleTypeId: selectedVehicleType,
                                          assignedDriverPrimaryId: selectedDriverPrimaryId,
                                          assignedDriverSecondaryId: selectedDriverSecondaryId,
                                          isActive: isActive,
                                        );

                                        await _createVehicle(newVehicle);
                                        Navigator.pop(context);
                                      } catch (e) {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Registration No is required')),
                                      );
                                    }
                                  },
                                  child: Center(
                                    child: _isSubmitting
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            'Create',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  void _showEditVehicleDialog(int index, Vehicle vehicle) {
  String regNo = vehicle.regNo;
  String model = vehicle.model ?? '';
  int? selectedVehicleType = vehicle.vehicleTypeId;
  String? selectedFuelType = vehicle.fuelType;
  int seatingCapacity = vehicle.seatingCapacity;
  int? selectedDriverPrimaryId = vehicle.assignedDriverPrimaryId;
  int? selectedDriverSecondaryId = vehicle.assignedDriverSecondaryId;
  double odometerLastReading = vehicle.odometerLastReading;
  bool isActive = vehicle.isActive;
  bool _isSubmitting = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sticky Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'Edit Vehicle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Divider
              Container(height: 1, color: Colors.grey.shade800),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Registration No Field
                      TextField(
                        controller: TextEditingController(text: regNo),
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Registration No *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.confirmation_number, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (value) => regNo = value,
                      ),
                      const SizedBox(height: 16),

                      // Model Field
                      TextField(
                        controller: TextEditingController(text: model),
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Model',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.directions_car, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (value) => model = value,
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Type Dropdown
                      DropdownButtonFormField<int>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.category, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedVehicleType,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._vehicleTypes.map((type) {
                            return DropdownMenuItem(
                              value: type.id,
                              child: Text(type.vehicleType, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fuel Type Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Fuel Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.local_gas_station, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedFuelType,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._fuelTypes.map((fuel) {
                            return DropdownMenuItem(
                              value: fuel,
                              child: Text(fuel, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedFuelType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Seating Capacity Field
                      TextField(
                        controller: TextEditingController(text: seatingCapacity.toString()),
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Seating Capacity',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.people, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => seatingCapacity = int.tryParse(value) ?? 4,
                      ),
                      const SizedBox(height: 16),

                      // Assigned Driver Dropdown
                      DropdownButtonFormField<int>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Assigned Driver',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedDriverPrimaryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._drivers.map((driver) {
                            return DropdownMenuItem(
                              value: driver.id,
                              child: Text(driver.displayname, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDriverPrimaryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Co-Driver Dropdown
                      DropdownButtonFormField<int>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Co-Driver',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedDriverSecondaryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._drivers.map((driver) {
                            return DropdownMenuItem(
                              value: driver.id,
                              child: Text(driver.displayname, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDriverSecondaryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Odometer Reading Field
                      TextField(
                        controller: TextEditingController(text: odometerLastReading.toStringAsFixed(1)),
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Last Odometer Reading',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.speed, color: Colors.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.yellow, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) => odometerLastReading = double.tryParse(value) ?? 0.0,
                      ),
                      const SizedBox(height: 8),

                      // Active/Inactive Toggle
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Active Vehicle",
                              style: TextStyle(color: Colors.white, fontSize: 16)
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isActive,
                                onChanged: (bool value) {
                                  setState(() {
                                    isActive = value;
                                  });
                                },
                                inactiveTrackColor: Colors.transparent,
                                inactiveThumbColor: Colors.yellow.shade600,
                                activeColor: Colors.yellow[600],
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Buttons Row
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade600, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.transparent,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isSubmitting ? null : () => Navigator.pop(context),
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Save Button
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isSubmitting ? [] : [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isSubmitting ? null : () async {
                                    try {
                                      setState(() {
                                        _isSubmitting = true;
                                      });

                                      final updatedVehicle = Vehicle(
                                        id: _vehicles[index].id,
                                        regNo: regNo,
                                        model: model.isEmpty ? null : model,
                                        fuelType: selectedFuelType,
                                        seatingCapacity: seatingCapacity,
                                        odometerLastReading: odometerLastReading,
                                        vehicleTypeId: selectedVehicleType,
                                        assignedDriverPrimaryId: selectedDriverPrimaryId,
                                        assignedDriverSecondaryId: selectedDriverSecondaryId,
                                        isActive: isActive,
                                      );

                                      await _updateVehicle(updatedVehicle);
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setState(() {
                                        _isSubmitting = false;
                                      });
                                    }
                                  },
                                  child: Center(
                                    child: _isSubmitting
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            'Save',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  void _showDeleteConfirmation(int index) {
  bool _isSubmitting = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Delete Vehicle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Text(
                  'Are you sure you want to delete ${_vehicles[index].regNo} vehicle?',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade600, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSubmitting ? null : () => Navigator.pop(context),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Delete Button
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isSubmitting ? Colors.grey : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isSubmitting ? [] : [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSubmitting ? null : () async {
                              try {
                                setState(() {
                                  _isSubmitting = true;
                                });

                                await _deleteVehicle(_vehicles[index].id, index);
                                Navigator.pop(context);
                              } catch (e) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
                            },
                            child: Center(
                              child: _isSubmitting
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      // Remove the data:image/png;base64, prefix if present
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      
      // Decode base64 to bytes
      return base64.decode(base64String);
    } catch (e) {
      throw Exception('Invalid QR code data');
    }
  }

}
