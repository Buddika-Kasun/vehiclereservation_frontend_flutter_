// screens/sub_screens/admin/vehicle_type_management_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/vehicleType_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class VehicleTypeManagementScreen extends StatefulWidget {
  const VehicleTypeManagementScreen({Key? key}) : super(key: key);

  @override
  _VehicleTypeManagementScreenState createState() => _VehicleTypeManagementScreenState();
}

class _VehicleTypeManagementScreenState extends State<VehicleTypeManagementScreen> {
  List<VehicleType> _vehicleTypes = [];
  int? _expandedIndex;
  bool _isLoading = true;
  bool _hasCompany = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCompanyAndLoadVehicleTypes();
  }

  Future<void> _checkCompanyAndLoadVehicleTypes() async {
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

        if (_hasCompany) {
          // Load vehicle types only if company exists
          await _loadVehicleTypes();
        } else {
          setState(() {
            _isLoading = false;
          });
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

  Future<void> _loadVehicleTypes() async {
    try {
      final response = await ApiService.getVehicleTypes();
      
      if (response['success'] == true) {
        final List<dynamic> vehicleTypesData = response['data']['costConfigurations'] ?? [];
        setState(() {
          _vehicleTypes = vehicleTypesData.map((data) => VehicleType.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load vehicle types');
      }
    } catch (e) {
      print('Error loading vehicle types: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createVehicleType(VehicleType vehicleType) async {
    try {
      final response = await ApiService.createVehicleType(vehicleType.toJson());
      
      if (response['success'] == true) {
        await _loadVehicleTypes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle Type created successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create vehicle type');
      }
    } catch (e) {
      print('Error creating vehicle type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create vehicle type: $e')),
      );
      rethrow;
    }
  }

  Future<void> _updateVehicleType(VehicleType vehicleType) async {
    try {
      final response = await ApiService.updateVehicleType(vehicleType.id, vehicleType.toJson());
      
      if (response['success'] == true) {
        await _loadVehicleTypes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle Type updated successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update vehicle type');
      }
    } catch (e) {
      print('Error updating vehicle type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vehicle type: $e')),
      );
      rethrow;
    }
  }

  Future<void> _deleteVehicleType(int id, int index) async {
    try {
      final response = await ApiService.deleteVehicleType(id);
      
      if (response['success'] == true) {
        setState(() {
          _vehicleTypes.removeAt(index);
          _expandedIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle Type deleted successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete vehicle type');
      }
    } catch (e) {
      print('Error deleting vehicle type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete vehicle type: $e')),
      );
      rethrow;
    }
  }

  String _generateShortName(String typeName) {
    if (typeName.isEmpty) return 'VT';
    final words = typeName.split(' ');
    final initials = words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildErrorWidget()
              : !_hasCompany
                  ? _buildNoCompanyWidget()
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
                'Vehicle Types',
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
                onTap: _showCreateVehicleTypeDialog,
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
                  _vehicleTypes.length.toString(),
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

        // Vehicle Types List
        Expanded(
          child: _vehicleTypes.isEmpty 
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicleTypes,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _vehicleTypes.length,
                    itemBuilder: (context, index) {
                      final vehicleType = _vehicleTypes[index];
                      final isExpanded = _expandedIndex == index;
                      final shortName = _generateShortName(vehicleType.vehicleType);
                      
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
                                color: ColorGenerator.getRandomColor(vehicleType.vehicleType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: isExpanded 
                                    ? Border.all(color: ColorGenerator.getRandomColor(vehicleType.vehicleType).withOpacity(0.2), width: 2)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      // Vehicle Type Icon
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: ColorGenerator.getRandomColor(vehicleType.vehicleType),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            shortName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      
                                      // Vehicle Type Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vehicleType.vehicleType,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Cost: \$${vehicleType.costPerKm.toStringAsFixed(2)}/KM',
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
                                    
                                    // Details Grid
                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          icon: Icons.attach_money,
                                          title: 'Cost per KM',
                                          value: '\$${vehicleType.costPerKm.toStringAsFixed(2)}',
                                        ),
                                        SizedBox(width: 24),
                                        _buildDetailItem(
                                          icon: Icons.calendar_today,
                                          title: 'Valid From',
                                          value: _formatDate(vehicleType.validFrom),
                                        ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          icon: Icons.circle,
                                          title: 'Status',
                                          value: vehicleType.isActive ? 'Active' : 'Inactive',
                                          valueColor: vehicleType.isActive ? Colors.green : Colors.orange,
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          icon: Icons.update,
                                          title: 'Created At',
                                          value: vehicleType.createdAt != null 
                                              ? _formatDate(vehicleType.createdAt!)
                                              : 'Never',
                                        ),
                                        SizedBox(width: 24),
                                        _buildDetailItem(
                                          icon: Icons.update,
                                          title: 'Updated At',
                                          value: vehicleType.updatedAt != null 
                                              ? _formatDate(vehicleType.updatedAt!)
                                              : 'Never',
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
                                                  _showEditVehicleTypeDialog(index, vehicleType);
                                                },
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Edit Vehicle Type',
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

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
            'No Vehicle Type Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your vehicle type to get started',
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

  void _showCreateVehicleTypeDialog() {
    String type = '';
    double costPerKm = 0.0;
    DateTime validFrom = DateTime.now();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'New Vehicle Type',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Vehicle Type Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type *',
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
                      hintText: 'e.g., Sedan, SUV, Truck',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => type = value,
                  ),
                  const SizedBox(height: 16),

                  // Cost per KM Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Cost per KM *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.yellow),
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
                      hintText: 'e.g., 2.50',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => costPerKm = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 16),

                  // Valid From Date Picker
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      readOnly: true,
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Valid From *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.yellow),
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.yellow),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.yellow),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.yellow, width: 1),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Select date',
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      controller: TextEditingController(text: _formatDate(validFrom)),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: validFrom,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && picked != validFrom) {
                          setState(() {
                            validFrom = picked;
                          });
                        }
                      },
                    ),
                  ),
                
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Active Vehicle Type",
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
                                if (type.isNotEmpty && costPerKm > 0) {
                                  try {
                                    setState(() {
                                      _isSubmitting = true;
                                    });

                                    final newVehicleType = VehicleType(
                                      id: 0,
                                      vehicleType: type,
                                      costPerKm: costPerKm,
                                      validFrom: validFrom,
                                      isActive: isActive,
                                    );

                                    await _createVehicleType(newVehicleType);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    setState(() {
                                      _isSubmitting = false;
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please fill all required fields with valid values')),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditVehicleTypeDialog(int index, VehicleType vehicleType) {
    String type = vehicleType.vehicleType;
    double costPerKm = vehicleType.costPerKm;
    DateTime validFrom = vehicleType.validFrom;
    bool isActive = vehicleType.isActive;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'Edit Vehicle Type',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Vehicle Type Field
                  TextField(
                    controller: TextEditingController(text: type),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type *',
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
                    onChanged: (value) => type = value,
                  ),
                  const SizedBox(height: 16),

                  // Cost per KM Field
                  TextField(
                    controller: TextEditingController(text: costPerKm.toStringAsFixed(2)),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Cost per KM *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.yellow),
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
                    onChanged: (value) => costPerKm = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 16),

                  // Valid From Date Picker
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      readOnly: true,
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Valid From *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.yellow),
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.yellow),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.yellow),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.yellow, width: 1),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Select date',
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      controller: TextEditingController(text: _formatDate(validFrom)),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: validFrom,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && picked != validFrom) {
                          setState(() {
                            validFrom = picked;
                          });
                        }
                      },
                    ),
                  ),
                
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Active Vehicle Type",
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

                                  final updatedVehicleType = VehicleType(
                                    id: _vehicleTypes[index].id,
                                    vehicleType: type,
                                    costPerKm: costPerKm,
                                    validFrom: validFrom,
                                    isActive: isActive,
                                  );

                                  await _updateVehicleType(updatedVehicleType);
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
                ],
              ),
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
                      'Delete Vehicle Type',
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
                    'Are you sure you want to delete ${_vehicleTypes[index].vehicleType} vehicle type?',
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

                                  await _deleteVehicleType(_vehicleTypes[index].id, index);
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

  // Common Widgets (Loading, Error, No Company)
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
              onPressed: _checkCompanyAndLoadVehicleTypes,
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

  Widget _buildNoCompanyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Company Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You need to create a company before managing vehicle types.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to company creation screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateCompanyScreen()));
              },
              icon: Icon(Icons.add_business),
              label: Text('Create Company'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}