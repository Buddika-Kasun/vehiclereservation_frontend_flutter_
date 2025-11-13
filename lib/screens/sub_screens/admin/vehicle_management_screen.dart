import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({Key? key}) : super(key: key);

  @override
  _VehicleManagementScreenState createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  //List<Vehicle> _vehicles = []; // Initialize as empty list
  List<Vehicle> _vehicles = [
    Vehicle(
      registrationNo: 'CAB-1234',
      model: 'Toyota Corolla',
      vehicleType: 'Sedan',
      fuelType: 'Petrol',
      seatingCapacity: 5,
      assignedDriver: 'John Smith',
      coDriver: 'Sarah Johnson',
      lastOdometerReading: 15000,
      isActive: true,
    ),
    Vehicle(
      registrationNo: 'SUV-5678',
      model: 'Honda CR-V',
      vehicleType: 'SUV',
      fuelType: 'Diesel',
      seatingCapacity: 7,
      assignedDriver: 'Mike Wilson',
      coDriver: '',
      lastOdometerReading: 22000,
      isActive: false,
    ),
    Vehicle(
      registrationNo: 'TRK-9012',
      model: 'Ford F-150',
      vehicleType: 'Truck',
      fuelType: 'Petrol',
      seatingCapacity: 3,
      assignedDriver: 'Emily Brown',
      coDriver: 'David Miller',
      lastOdometerReading: 30000,
      isActive: true,
    ),
  ];

  // Sample data for dropdowns
  final List<String> _vehicleTypes = [
    'Sedan',
    'SUV',
    'Truck',
    'Van',
    'Bus',
    'Motorcycle',
    'Pickup',
    'Minivan'
  ];

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
    'LPG'
  ];

  final List<String> _drivers = [
    'John Smith',
    'Sarah Johnson',
    'Mike Wilson',
    'Emily Brown',
    'David Miller',
    'Lisa Anderson',
    'Robert Taylor',
    'Maria Garcia'
  ];

  int? _expandedIndex;

  String _generateShortName(String registrationNo) {
    if (registrationNo.isEmpty) return 'VH';
    // Get last 3 characters of registration number
    return registrationNo.length > 3 
        ? registrationNo.substring(registrationNo.length - 3).toUpperCase()
        : registrationNo.toUpperCase();
  }

  void _downloadQRCode(String registrationNo) {
    // Simulate QR code download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR Code for $registrationNo downloaded')),
    );
    // In real implementation, you would generate and download QR code here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
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
                  onTap: () {
                    _showCreateVehicleDialog();
                  },
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
          // In the ListView.builder, replace the Expanded widget with a Container with fixed height:

// Departments List
Expanded(
  child: _vehicles.isEmpty 
      ? _buildEmptyState()
      : ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 24),
          itemCount: _vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = _vehicles[index];
            final isExpanded = _expandedIndex == index;
            final shortName = _generateShortName(vehicle.registrationNo);
            
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
                      color: ColorGenerator.getRandomColor(vehicle.registrationNo).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: isExpanded 
                          ? Border.all(color: ColorGenerator.getRandomColor(vehicle.registrationNo).withOpacity(0.2), width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Changed from max to min
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
                                color: ColorGenerator.getRandomColor(vehicle.registrationNo),
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
                                    vehicle.registrationNo,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${vehicle.model} • ${vehicle.vehicleType}',
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
                                value: vehicle.model,
                              ),
                              SizedBox(width: 24),
                              _buildDetailItem(
                                icon: Icons.local_gas_station,
                                title: 'Fuel Type',
                                value: vehicle.fuelType,
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
                                value: '${vehicle.lastOdometerReading} km',
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
                                value: vehicle.assignedDriver,
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
                                value: vehicle.coDriver.isNotEmpty ? vehicle.coDriver : 'Not assigned',
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
                                    // QR Code Placeholder (Square)
                                    Container(
                                      width: 120,
                                      height: 120,
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
                                            vehicle.registrationNo,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12),
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
                                          onTap: () {
                                            _downloadQRCode(vehicle.registrationNo);
                                          },
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
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'sedan':
        return Icons.directions_car;
      case 'suv':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      case 'van':
        return Icons.airport_shuttle;
      case 'bus':
        return Icons.directions_bus;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'pickup':
        return Icons.local_shipping;
      case 'minivan':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
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

  void _showCreateVehicleDialog() {
    String registrationNo = '';
    String model = '';
    String? selectedVehicleType = '';
    String? selectedFuelType = '';
    int seatingCapacity = 0;
    String? selectedDriver = '';
    String? selectedCoDriver = '';
    int lastOdometerReading = 0;
    bool isActive = true;

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
            // Sticky Title - Outside of ScrollView
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                //color: Colors.black,
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
            Container(
              height: 1,
              color: Colors.grey.shade800,
            ),
            
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
                      onChanged: (value) => registrationNo = value,
                    ),
                    const SizedBox(height: 16),

                    // Model Field
                    TextField(
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Model *',
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
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.yellow),
                        prefixIcon: const Icon(Icons.category, color: Colors.yellow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.yellow, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      value: selectedVehicleType?.isEmpty ?? true ? null : selectedVehicleType,
                      items: _vehicleTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type, style: const TextStyle(color: Colors.yellow)),
                        );
                      }).toList(),
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
                        labelText: 'Fuel Type *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.yellow),
                        prefixIcon: const Icon(Icons.local_gas_station, color: Colors.yellow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.yellow, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      value: selectedFuelType?.isEmpty ?? true ? null : selectedFuelType,
                      items: _fuelTypes.map((fuel) {
                        return DropdownMenuItem(
                          value: fuel,
                          child: Text(fuel, style: const TextStyle(color: Colors.yellow)),
                        );
                      }).toList(),
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
                        labelText: 'Seating Capacity *',
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
                      onChanged: (value) => seatingCapacity = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),

                    // Assigned Driver Dropdown
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Assigned Driver *',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.yellow),
                        prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.yellow, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      value: selectedDriver?.isEmpty ?? true ? null : selectedDriver,
                      items: _drivers.map((driver) {
                        return DropdownMenuItem(
                          value: driver,
                          child: Text(driver, style: const TextStyle(color: Colors.yellow)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDriver = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Co-Driver Dropdown
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Co-Driver',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.yellow),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.yellow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.yellow, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      value: selectedCoDriver?.isEmpty ?? true ? null : selectedCoDriver,
                      items: [DropdownMenuItem(value: '', child: Text('None', style: TextStyle(color: Colors.yellow)))] 
                        + _drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver,
                            child: Text(driver, style: const TextStyle(color: Colors.yellow)),
                          );
                        }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCoDriver = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Odometer Reading Field
                    TextField(
                      style: const TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        labelText: 'Last Odometer Reading *',
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
                        hintText: 'e.g., 15000',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => lastOdometerReading = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 8),

                    // Active/Inactive Toggle
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Active Vehicle",
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
                                onTap: () => Navigator.pop(context),
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
                              color: Colors.yellow[600],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
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
                                onTap: () {
                                  if (registrationNo.isNotEmpty && model.isNotEmpty && 
                                      selectedVehicleType != null && selectedFuelType != null &&
                                      selectedDriver != null && seatingCapacity > 0) {
                                    final newVehicle = Vehicle(
                                      registrationNo: registrationNo,
                                      model: model,
                                      vehicleType: selectedVehicleType!,
                                      fuelType: selectedFuelType!,
                                      seatingCapacity: seatingCapacity,
                                      assignedDriver: selectedDriver!,
                                      coDriver: selectedCoDriver ?? '',
                                      lastOdometerReading: lastOdometerReading,
                                      isActive: isActive,
                                    );
                                    setState(() {
                                      _vehicles.add(newVehicle);
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Vehicle created successfully')),
                                    );
                                  }
                                },
                                child: Center(
                                  child: Text(
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
                    const SizedBox(height: 8), // Extra padding at bottom
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
  String registrationNo = vehicle.registrationNo;
  String model = vehicle.model;
  String? selectedVehicleType = vehicle.vehicleType;
  String? selectedFuelType = vehicle.fuelType;
  int seatingCapacity = vehicle.seatingCapacity;
  String? selectedDriver = vehicle.assignedDriver;
  String? selectedCoDriver = vehicle.coDriver;
  int lastOdometerReading = vehicle.lastOdometerReading;
  bool isActive = vehicle.isActive;

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
              // Sticky Title - Outside of ScrollView
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  //color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
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
              Container(
                height: 1,
                color: Colors.grey.shade800,
              ),
              
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
                        controller: TextEditingController(text: registrationNo),
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
                        onChanged: (value) => registrationNo = value,
                      ),
                      const SizedBox(height: 16),

                      // Model Field
                      TextField(
                        controller: TextEditingController(text: model),
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Model *',
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
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.category, color: Colors.yellow),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedVehicleType,
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(color: Colors.yellow)),
                          );
                        }).toList(),
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
                          labelText: 'Fuel Type *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.local_gas_station, color: Colors.yellow),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedFuelType,
                        items: _fuelTypes.map((fuel) {
                          return DropdownMenuItem(
                            value: fuel,
                            child: Text(fuel, style: const TextStyle(color: Colors.yellow)),
                          );
                        }).toList(),
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
                          labelText: 'Seating Capacity *',
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
                        onChanged: (value) => seatingCapacity = int.tryParse(value) ?? 0,
                      ),
                      const SizedBox(height: 16),

                      // Assigned Driver Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Assigned Driver *',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedDriver,
                        items: _drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver,
                            child: Text(driver, style: const TextStyle(color: Colors.yellow)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDriver = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Co-Driver Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Co-Driver',
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: const TextStyle(color: Colors.yellow),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.yellow),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: selectedCoDriver,
                        items: [DropdownMenuItem(value: '', child: Text('None', style: TextStyle(color: Colors.yellow)))] 
                          + _drivers.map((driver) {
                            return DropdownMenuItem(
                              value: driver,
                              child: Text(driver, style: const TextStyle(color: Colors.yellow)),
                            );
                          }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCoDriver = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Last Odometer Reading Field
                      TextField(
                        controller: TextEditingController(text: lastOdometerReading.toString()),
                        style: const TextStyle(color: Colors.yellow),
                        decoration: InputDecoration(
                          labelText: 'Last Odometer Reading *',
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
                        keyboardType: TextInputType.number,
                        onChanged: (value) => lastOdometerReading = int.tryParse(value) ?? 0,
                      ),
                      const SizedBox(height: 8),

                      // Active/Inactive Toggle
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Active Vehicle",
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
                                  onTap: () => Navigator.pop(context),
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
                                color: Colors.yellow[600],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
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
                                  onTap: () {
                                    final updatedVehicle = Vehicle(
                                      registrationNo: registrationNo,
                                      model: model,
                                      vehicleType: selectedVehicleType!,
                                      fuelType: selectedFuelType!,
                                      seatingCapacity: seatingCapacity,
                                      assignedDriver: selectedDriver!,
                                      coDriver: selectedCoDriver ?? '',
                                      lastOdometerReading: lastOdometerReading,
                                      isActive: isActive,
                                    );
                                    setState(() {
                                      _vehicles[index] = updatedVehicle;
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Vehicle updated successfully')),
                                    );
                                  },
                                  child: Center(
                                    child: Text(
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
                      const SizedBox(height: 8), // Extra padding at bottom
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
  showDialog(
    context: context,
    builder: (context) => Dialog(
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
            // Title
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
              'Are you sure you want to delete ${_vehicles[index].registrationNo} vehicle?',
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
                        onTap: () => Navigator.pop(context),
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
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
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
                        onTap: () {
                          setState(() {
                            _vehicles.removeAt(index);
                            _expandedIndex = null;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vehicle deleted successfully')),
                          );
                        },
                        child: const Center(
                          child: Text(
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
    ),
  );
}
}

class Vehicle {
  final String registrationNo;
  final String model;
  final String vehicleType;
  final String fuelType;
  final int seatingCapacity;
  final String assignedDriver;
  final String coDriver;
  final int lastOdometerReading;
  final bool isActive;

  Vehicle({
    required this.registrationNo,
    required this.model,
    required this.vehicleType,
    required this.fuelType,
    required this.seatingCapacity,
    required this.assignedDriver,
    required this.coDriver,
    required this.lastOdometerReading,
    required this.isActive,
  });

}