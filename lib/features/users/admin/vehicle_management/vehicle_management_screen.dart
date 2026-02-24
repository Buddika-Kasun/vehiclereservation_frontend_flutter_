// lib/features/vehicles/screens/vehicle_management_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicleType_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicle_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_management/widgets/management_vehicle_card.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/list_content.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({Key? key}) : super(key: key);

  @override
  _VehicleManagementScreenState createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Vehicle> _vehicles = [];
  List<VehicleType> _vehicleTypes = [];
  List<ShortUser> _drivers = [];
  int? _expandedIndex;
  bool _isLoading = true;
  String _loadingMsg = 'Loading...';
  bool _hasCompany = false;
  bool _hasVehicleTypes = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Fuel type options
  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
  ];

  // Scroll controller for list
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkCompanyAndLoadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkCompanyAndLoadData() async {
    try {
      setState(() {
        _loadingMsg = 'Loading vehicles...';
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
          final List<dynamic> vehicleTypesData =
              vehicleTypesResponse['data']['costConfigurations'] ?? [];
          setState(() {
            _hasVehicleTypes = vehicleTypesData.isNotEmpty;
            _vehicleTypes = vehicleTypesData
                .map((data) => VehicleType.fromJson(data))
                .toList();
          });

          if (_hasCompany && _hasVehicleTypes) {
            // Load all data only if company and vehicle types exist
            await Future.wait([_loadVehicles(), _loadDrivers()]);
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          throw Exception(
            vehicleTypesResponse['message'] ?? 'Failed to check vehicle types',
          );
        }
      } else {
        throw Exception(
          companyResponse['message'] ?? 'Failed to check company status',
        );
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
      setState(() {
        _loadingMsg = 'Loading vehicles...';
      });

      final response = await ApiService.getVehicles();

      if (response['success'] == true) {
        final List<dynamic> vehiclesData = response['data']['vehicles'] ?? [];
        setState(() {
          _vehicles = vehiclesData
              .map((data) => Vehicle.fromJson(data))
              .toList();
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
      final response = await ApiService.getUsersByRole('driver');

      if (response['success'] == true) {
        final List<dynamic> usersData = response['data']['users'] ?? [];
        setState(() {
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
      // Pop the dialog immediately
      Navigator.pop(context);

      // Show loading overlay
      setState(() {
        _loadingMsg = 'Processing...';
        _isLoading = true;
      });

      final response = await ApiService.createVehicle(vehicle.toJson());

      if (response['success'] == true) {
        if (mounted) {
          MessageOverlay.showSuccess(
            context: context,
            message: "Vehicle created successfully!",
            duration: const Duration(seconds: 2),
            position: OverlayPosition.top,
            showBackgroundOverlay: true,
          );
        }
        await _loadVehicles();
      } 
      else {
        throw Exception(response['message'] ?? 'Failed to create vehicle');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error creating vehicle: $e');
      if (mounted) {
        MessageOverlay.showError(
          context: context,
          message: "Failed to create vehicle: ${e.toString()}",
          duration: const Duration(seconds: 3),
          showOkButton: true,
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
      rethrow;
    }
  }

  Future<void> _updateVehicle(Vehicle vehicle) async {
    try {
      // Pop the dialog immediately
      Navigator.pop(context);

      // Show loading overlay
      setState(() {
        _loadingMsg = 'Processing...';
        _isLoading = true;
      });

      final response = await ApiService.updateVehicle(
        vehicle.id,
        vehicle.toJson(),
      );

      if (response['success'] == true) {
        if (mounted) {
          MessageOverlay.showSuccess(
            context: context,
            message: "Vehicle updated successfully!",
            duration: const Duration(seconds: 2),
            position: OverlayPosition.top,
            showBackgroundOverlay: true,
          );
        }
        await _loadVehicles();
      } 
      else {
        throw Exception(response['message'] ?? 'Failed to update vehicle');
      }
    } catch (e) {
      print('Error updating vehicle: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        MessageOverlay.showError(
          context: context,
          message: "Failed to update vehicle: ${e.toString()}",
          duration: const Duration(seconds: 3),
          showOkButton: true,
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteVehicle(int id) async {
    try {

      // Show loading overlay
      setState(() {
        _loadingMsg = 'Processing...';
        _expandedIndex = null;
        _isLoading = true;
      });

      final response = await ApiService.deleteVehicle(id);

      if (response['success'] == true) {
        if (mounted) {
          MessageOverlay.showSuccess(
            context: context,
            message: "Vehicle deleted successfully!",
            duration: const Duration(seconds: 2),
            position: OverlayPosition.top,
            showBackgroundOverlay: true,
          );
        }
        await _loadVehicles();
      } 
      else {
        throw Exception(response['message'] ?? 'Failed to delete vehicle');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error deleting vehicle: $e');
      if (mounted) {
        MessageOverlay.showError(
          context: context,
          message: "Failed to delete vehicle: ${e.toString()}",
          duration: const Duration(seconds: 3),
          showOkButton: true,
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
      rethrow;
    }
  }

  Future<void> _downloadQRCode(String regNo, String? qrCodeBase64) async {
    if (qrCodeBase64 == null || qrCodeBase64.isEmpty) {
      MessageOverlay.showError(
        context: context,
        message: 'No QR code available for download',
        duration: const Duration(seconds: 2),
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                color: Color(0xFFF9C80E),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Preparing QR Code...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Navigator.pop(context);
        MessageOverlay.showError(
          context: context,
          message: 'Storage permission is required to download QR code',
          duration: const Duration(seconds: 2),
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
        return;
      }

      // Convert base64 to bytes
      final bytes = _base64ToImage(qrCodeBase64);

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: '${regNo}_qrcode_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      Navigator.pop(context);

      if (result['isSuccess'] == true) {
        MessageOverlay.showSuccess(
          context: context,
          message: "QR code saved to gallery successfully!",
          duration: const Duration(seconds: 2),
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      } else {
        MessageOverlay.showError(
          context: context,
          message: 'Failed to save QR code to gallery',
          duration: const Duration(seconds: 3),
          showOkButton: true,
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        MessageOverlay.showError(
          context: context,
          message: 'Failed to download QR code: ${e.toString()}',
          duration: const Duration(seconds: 3),
          showOkButton: true,
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingMessage: _loadingMsg,
        child: _hasError
            ? _buildErrorWidget()
            : !_isLoading && (!_hasCompany || !_hasVehicleTypes)
            ? _buildRequirementsWidget()
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        TripHeader(
          title: 'Vehicle Management',
          subtitle: 'Create, edit and manage vehicles',
          onRefresh: _refreshData,
        ),

        // Create New Button - No shadow
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF9C80E),
              borderRadius: BorderRadius.circular(8),
              // Removed boxShadow
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showCreateVehicleDialog,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create New Vehicle',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
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

        CountBadge(totalCount: _vehicles.length, label: 'Vehicles'),

        const SizedBox(height: 4),

        Expanded(
          child: ListContent<Vehicle>(
            scrollController: _scrollController,
            items: _vehicles,
            isLoading: _isLoading,
            loadingMore: false,
            errorMessage: '',
            hasMore: false,
            onRetry: _refreshData,
            emptyStateMessage: 'No vehicles found',
            emptyStateIcon: Icons.directions_car,
            buildItem: (vehicle) {
              final index = _vehicles.indexOf(vehicle);

              return ManagementVehicleCard(
                vehicle: vehicle,
                isExpanded: _expandedIndex == index,
                onTap: () {
                  setState(() {
                    _expandedIndex = _expandedIndex == index ? null : index;
                  });
                },
                onEdit: () => _showEditVehicleDialog(vehicle),
                onDelete: () => _showDeleteConfirmation(vehicle),
                onDownloadQR: () =>
                    _downloadQRCode(vehicle.regNo, vehicle.qrCode),
                vehicleTypes: _vehicleTypes,
                drivers: _drivers,
                fuelTypes: _fuelTypes,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadVehicles();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkCompanyAndLoadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C80E),
                foregroundColor: Colors.black,
                elevation: 0, // No shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Requirements Missing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              !_hasCompany
                  ? 'You need to create a company before managing vehicles.'
                  : 'You need to create vehicle types before managing vehicles.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVehicleDialog() {
    setState(() {
      _expandedIndex = null;
    });

    showDialog(
      context: context,
      builder: (context) => VehicleFormDialog(
        title: 'Create New Vehicle',
        vehicleTypes: _vehicleTypes,
        drivers: _drivers,
        fuelTypes: _fuelTypes,
        onSubmit: (vehicle) async {
          await _createVehicle(vehicle);
        },
      ),
    );
  }

  void _showEditVehicleDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => VehicleFormDialog(
        title: 'Edit Vehicle',
        vehicle: vehicle,
        vehicleTypes: _vehicleTypes,
        drivers: _drivers,
        fuelTypes: _fuelTypes,
        onSubmit: (updatedVehicle) async {
          //updatedVehicle.id = vehicle.id;
          await _updateVehicle(updatedVehicle);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        vehicle: vehicle,
        onConfirm: () async {
          Navigator.pop(context);
          await _deleteVehicle(vehicle.id);
        },
      ),
    );
  }
}

// Vehicle Form Dialog Component
class VehicleFormDialog extends StatefulWidget {
  final String title;
  final Vehicle? vehicle;
  final List<VehicleType> vehicleTypes;
  final List<ShortUser> drivers;
  final List<String> fuelTypes;
  final Function(Vehicle) onSubmit;

  const VehicleFormDialog({
    Key? key,
    required this.title,
    this.vehicle,
    required this.vehicleTypes,
    required this.drivers,
    required this.fuelTypes,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _VehicleFormDialogState createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  late String _regNo;
  late String _model;
  late int? _selectedVehicleType;
  late String? _selectedFuelType;
  late int _seatingCapacity;
  late int? _selectedDriverPrimaryId;
  late int? _selectedDriverSecondaryId;
  late double _odometerLastReading;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      // Edit mode
      _regNo = widget.vehicle!.regNo;
      _model = widget.vehicle!.model ?? '';
      _selectedVehicleType = widget.vehicle!.vehicleTypeId;
      _selectedFuelType = widget.vehicle!.fuelType;
      _seatingCapacity = widget.vehicle!.seatingCapacity;
      _selectedDriverPrimaryId = widget.vehicle!.assignedDriverPrimaryId;
      _selectedDriverSecondaryId = widget.vehicle!.assignedDriverSecondaryId;
      _odometerLastReading = widget.vehicle!.odometerLastReading;
      _isActive = widget.vehicle!.isActive;
    } else {
      // Create mode
      _regNo = '';
      _model = '';
      _selectedVehicleType = null;
      _selectedFuelType = null;
      _seatingCapacity = 4;
      _selectedDriverPrimaryId = null;
      _selectedDriverSecondaryId = null;
      _odometerLastReading = 0.0;
      _isActive = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9C80E),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Registration No
                    TextField(
                      controller: TextEditingController(text: _regNo),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Registration No *',
                        icon: Icons.confirmation_number,
                      ),
                      onChanged: (value) => _regNo = value,
                    ),
                    const SizedBox(height: 16),

                    // Model
                    TextField(
                      controller: TextEditingController(text: _model),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Model',
                        icon: Icons.directions_car,
                      ),
                      onChanged: (value) => _model = value,
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Type
                    DropdownButtonFormField<int>(
                      value: _selectedVehicleType,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Vehicle Type',
                        icon: Icons.category,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...widget.vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type.id,
                            child: Text(
                              type.vehicleType,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedVehicleType = value),
                    ),
                    const SizedBox(height: 16),

                    // Fuel Type
                    DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Fuel Type',
                        icon: Icons.local_gas_station,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...widget.fuelTypes.map((fuel) {
                          return DropdownMenuItem(
                            value: fuel,
                            child: Text(
                              fuel,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedFuelType = value),
                    ),
                    const SizedBox(height: 16),

                    // Seating Capacity
                    TextField(
                      controller: TextEditingController(
                        text: _seatingCapacity.toString(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Seating Capacity',
                        icon: Icons.people,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _seatingCapacity = int.tryParse(value) ?? 4,
                    ),
                    const SizedBox(height: 16),

                    // Primary Driver
                    DropdownButtonFormField<int>(
                      value: _selectedDriverPrimaryId,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Primary Driver',
                        icon: Icons.person,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...widget.drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver.id,
                            child: Text(
                              driver.displayname,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedDriverPrimaryId = value),
                    ),
                    const SizedBox(height: 16),

                    // Secondary Driver
                    DropdownButtonFormField<int>(
                      value: _selectedDriverSecondaryId,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Secondary Driver',
                        icon: Icons.person_outline,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...widget.drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver.id,
                            child: Text(
                              driver.displayname,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedDriverSecondaryId = value),
                    ),
                    const SizedBox(height: 16),

                    // Odometer Reading
                    TextField(
                      controller: TextEditingController(
                        text: _odometerLastReading.toStringAsFixed(1),
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        label: 'Last Odometer Reading (km)',
                        icon: Icons.speed,
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) =>
                          _odometerLastReading = double.tryParse(value) ?? 0.0,
                    ),
                    const SizedBox(height: 16),

                    // Active Switch
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Vehicle',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                            activeColor: const Color(0xFFF9C80E),
                            activeTrackColor: const Color(
                              0xFFF9C80E,
                            ).withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with buttons - No shadows
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0, // No shadow
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9C80E),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0, // No shadow
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              widget.vehicle != null ? 'Update' : 'Create',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(color: Color(0xFFF9C80E)),
      prefixIcon: Icon(icon, color: const Color(0xFFF9C80E)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF9C80E), width: 1),
      ),
      filled: true,
      fillColor: Colors.transparent,
    );
  }

  Future<void> _handleSubmit() async {
    if (_regNo.isEmpty) {
      MessageOverlay.showError(
        context: context,
        message: 'Registration number is required',
        duration: const Duration(seconds: 2),
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final vehicle = Vehicle(
        id: widget.vehicle?.id ?? 0,
        regNo: _regNo,
        model: _model.isEmpty ? null : _model,
        fuelType: _selectedFuelType,
        seatingCapacity: _seatingCapacity,
        odometerLastReading: _odometerLastReading,
        vehicleTypeId: _selectedVehicleType,
        assignedDriverPrimaryId: _selectedDriverPrimaryId,
        assignedDriverSecondaryId: _selectedDriverSecondaryId,
        isActive: _isActive,
      );

      await widget.onSubmit(vehicle);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }
}

// Delete Confirmation Dialog - No shadows
class DeleteConfirmationDialog extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    Key? key,
    required this.vehicle,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Vehicle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete ${vehicle.regNo}?',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0, // No shadow
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0, // No shadow
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }
}
