import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/available_vehicles_response.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:intl/intl.dart';

class ReviewVehicleSelectionScreen extends StatefulWidget {
  final String tripId;
  final double distance;

  const ReviewVehicleSelectionScreen({Key? key, required this.tripId, required this.distance})
    : super(key: key);

  @override
  _ReviewVehicleSelectionScreenState createState() =>
      _ReviewVehicleSelectionScreenState();
}

class _ReviewVehicleSelectionScreenState
    extends State<ReviewVehicleSelectionScreen> {
  List<AvailableVehicle> _allVehicles = [];
  AvailableVehicle? _selectedVehicle;
  bool _isLoading = true;
  bool _isBooking = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles(clear: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_hasMore && !_isLoading) {
        _loadVehicles(clear: false);
      }
    }
  }

  Future<void> _loadVehicles({bool clear = false}) async {
    try {
      if (clear) {
        setState(() {
          _currentPage = 0;
          _allVehicles.clear();
          _hasMore = true;
        });
      }

      setState(() => _isLoading = true);

      final response = await ApiService.getReviewAvailableVehicles(
        widget.tripId,
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      setState(() {
        if (clear) {
          _allVehicles = response.allVehicles;
        } else {
          _allVehicles.addAll(response.allVehicles);
        }
        _hasMore = response.allVehicles.length >= _pageSize;
        _isLoading = false;
        if (!clear) _currentPage++;
      });

      if (_allVehicles.isEmpty) {
        _showMessage('No vehicles available for your trip');
      }
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() => _isLoading = false);
      _showMessage('Error loading vehicles');
    }
  }

  Future<void> _bookVehicle() async {
    if (_selectedVehicle == null) {
      _showMessage('Please select a vehicle');
      return;
    }

    final confirm = await _showConfirmationDialog(
      'Confirm Booking',
      'Are you sure you want to book ${_selectedVehicle!.vehicle.model} (${_selectedVehicle!.vehicle.regNo})?',
    );

    if (!confirm) return;

    setState(() => _isBooking = true);

    try {
      final success = await ApiService.addVehicleToTrip(
        tripId: widget.tripId,
        vehicleId: _selectedVehicle!.vehicle.id.toString(),
      );

      if (success) {
        //_showMessage('Vehicle booked successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vehicle booked successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success with reload flag
      } else {
        //_showMessage('Failed to book vehicle');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book vehicle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error booking vehicle: $e');
      //_showMessage('Error booking vehicle');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking vehicle'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  Future<bool> _onBackPressed() async {
    if (_selectedVehicle != null) {
      final confirm = await _showConfirmationDialog(
        'Discard Selection',
        'You have selected a vehicle. Are you sure you want to go back without booking?',
      );
      if (!confirm) return false;
    }

    Navigator.of(context).pop(true); // Return no reload
    return true;
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(213, 74, 73, 73),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('OK', style: TextStyle(color: Colors.yellow[600])),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.yellow[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return false; // We handle navigation manually
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            _buildHeader(), // Add header
            Expanded(
              child: _buildContent(), // Extract content to separate method
            ),
            if (_selectedVehicle != null) _buildBookButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 60.0; // Base height for app bar content

    return Container(
      height: statusBarHeight + appBarHeight,
      padding: EdgeInsets.only(
        top: statusBarHeight,
        left: 16,
        right: 16,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onBackPressed(), // Always use our back method
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFF9C80E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text(
                  "Select Vehicle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (_isConnected ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Extract content to a separate method
  Widget _buildContent() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _loadVehicles(clear: true);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            style: TextStyle(color: Colors.white),
            onSubmitted: (value) => _loadVehicles(clear: true),
          ),
        ),

        // Vehicle Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Available Vehicles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _allVehicles.length.toString(),
                  style: TextStyle(color: Colors.yellow[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Vehicles List
        Expanded(
          child: _isLoading && _allVehicles.isEmpty
              ? Center(
                  child: CircularProgressIndicator(color: Colors.yellow[600]),
                )
              : _allVehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.car_repair, color: Colors.grey, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No vehicles found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      if (_searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _loadVehicles(clear: true);
                          },
                          child: Text(
                            'Clear search',
                            style: TextStyle(color: Colors.yellow[600]),
                          ),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadVehicles(clear: true),
                  color: Colors.yellow[600],
                  backgroundColor: Colors.black,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _allVehicles.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _allVehicles.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    color: Colors.yellow[600],
                                  )
                                : Container(),
                          ),
                        );
                      }

                      final vehicle = _allVehicles[index];
                      final isSelected =
                          _selectedVehicle?.vehicle.id == vehicle.vehicle.id;

                      return _buildVehicleCard(vehicle, isSelected);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Book button widget
  Widget _buildBookButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isBooking ? null : _bookVehicle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[600],
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isBooking
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'ASSIGN ${_selectedVehicle!.vehicle.regNo}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  final formatter = NumberFormat('#,##0', 'en_US');

  Widget _buildVehicleCard(AvailableVehicle availableVehicle, bool isSelected) {
    final vehicle = availableVehicle.vehicle;
    final availableSeats = vehicle.seatingAvailability ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: isSelected
          ? Colors.yellow[600]!.withOpacity(0.15)
          : Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.yellow[600]! : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedVehicle = isSelected ? null : availableVehicle;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_exchange, color: Colors.cyanAccent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Est. Cost: ',
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                        ),
                        Text(
                          'LKR ${formatter.format((double.parse(availableVehicle.vehicle.costPerKm.toString()) * widget.distance).round())}',
                          style: TextStyle(
                            color: Colors.cyanAccent, 
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recommendation badge
                  if (availableVehicle.isRecommended)
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //Icon(Icons.star, color: Colors.green, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.greenAccent, 
                              fontSize: 12,
                              fontWeight: FontWeight.w600  
                            ),
                          ),
                        ],
                      ),
                    ),

                ]
              ),

              // Header row with model and selection indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicle.model ?? 'Unknown Model',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.yellow[600]),
                ],
              ),

              SizedBox(height: 4),

              // Registration number
              Text(
                vehicle.regNo,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),

              SizedBox(height: 12),

              // Vehicle details in rows
              _buildDetailRow(
                icon: Icons.people,
                text:
                    '${availableSeats > 0 ? availableSeats : 0} seats available',
              ),

              /*
              _buildDetailRow(
                icon: Icons.location_on,
                text:
                    '${(availableVehicle.distanceFromStart / 1000).toStringAsFixed(1)} km away',
              ),

              _buildDetailRow(
                icon: Icons.access_time,
                text:
                    '${availableVehicle.estimatedArrivalTime.toStringAsFixed(0)} min ETA',
              ),
              */

              // Driver info if available
              if (vehicle.assignedDriverPrimaryName != null)
                _buildDetailRow(
                  icon: Icons.person,
                  text: 'Driver: ${vehicle.assignedDriverPrimaryName!}',
                ),

              // Conflict warning
              if (availableVehicle.isInConflict)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Schedule conflict',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
        ],
      ),
    );
  }

}
