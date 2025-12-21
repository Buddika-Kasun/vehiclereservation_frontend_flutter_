import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/constant.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/available_vehicles_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_booking_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_request_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/create_trip_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final Trip? existingTrip; // For viewing existing trips
  final bool isViewMode; // Whether we're viewing an existing trip

  const VehicleSelectionScreen({
    Key? key,
    required this.tripData,
    this.existingTrip,
    this.isViewMode = false,
  }) : super(key: key);

  @override
  _VehicleSelectionScreenState createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  List<AvailableVehicle> _recommendedVehicles = [];
  List<AvailableVehicle> _allVehicles = [];
  AvailableVehicle? _selectedVehicle;
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isCanceling = false;
  bool _isPanelExpanded = false;
  Trip? _bookedTrip;
  String _bookingStatus = 'initial';
  Timer? _statusTimer;
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(6.9271, 79.8612);
  DateTime? _approvedTime;
  DateTime? _estimatedArrivalTime;

  @override
  void initState() {
    super.initState();
    
    if (widget.isViewMode && widget.existingTrip != null) {
      // Load existing trip data
      _loadExistingTrip();
    } else {
      // Load available vehicles for new trip
      _loadAvailableVehicles();
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _loadExistingTrip() {
    setState(() {
      _bookedTrip = widget.existingTrip;
      _bookingStatus = widget.existingTrip?.status ?? 'pending';
      _isLoading = false;
    });

    if (_bookingStatus == 'pending' || _bookingStatus == 'approved') {
      _startStatusPolling(_bookedTrip!.id);
    }

    _fitMapToRoute();
  }

  Future<void> _loadAvailableVehicles() async {
    try {
      setState(() => _isLoading = true);
      
      // Create clean location data without routeData for API call
      final locationData = Map<String, dynamic>.from(widget.tripData['locationData']);
      //locationData.remove('routeData');
      
      // Create trip request WITHOUT vehicleId for available vehicles endpoint
      final tripRequest = TripRequest(
        locationData: locationData,
        scheduleData: widget.tripData['scheduleData'],
        passengerData: widget.tripData['passengerData'],
      );

      print("Loading available vehicles...");
      final response = await ApiService.getAvailableVehicles(tripRequest);
      print('Available vehicles loaded successfully!');
      
      setState(() {
        _recommendedVehicles = response.recommendedVehicles;
        _allVehicles = response.allVehicles;
        _isLoading = false;
      });

      print('Found ${_recommendedVehicles.length} recommended vehicles and ${_allVehicles.length} all vehicles');
      
      if (_recommendedVehicles.isEmpty && _allVehicles.isEmpty) {
        _showMessage('No vehicles available for your trip');
      }
      
      _fitMapToRoute();
    } catch (e) {
      print('Error in _loadAvailableVehicles: $e');
      setState(() => _isLoading = false);
      _showMessage('Error loading vehicles: ${e.toString()}');
    }
  }

  void _fitMapToRoute() {
    try {
      final locations = widget.tripData['locationData'];
      final startCoords = locations['startLocation']['coordinates']['coordinates'];
      final endCoords = locations['endLocation']['coordinates']['coordinates'];
      
      final startLatLng = LatLng(startCoords[1], startCoords[0]);
      final endLatLng = LatLng(endCoords[1], endCoords[0]);
      
      final bounds = LatLngBounds.fromPoints([startLatLng, endLatLng]);
      
      _mapController.fitBounds(
        bounds,
        options: FitBoundsOptions(padding: EdgeInsets.all(50)),
      );
    } catch (e) {
      print('Error fitting map to route: $e');
      _mapController.move(_center, 14);
    }
  }

  Future<void> _bookTrip() async {
    if (_selectedVehicle == null) {
      _showMessage('Please select a vehicle');
      return;
    }

    // Prevent multiple bookings
    if (_isBooking || _bookedTrip != null) {
      return;
    }

    try {
      setState(() => _isBooking = true);

      // Create clean location data without routeData for booking too
      final locationData = Map<String, dynamic>.from(widget.tripData['locationData']);
      //locationData.remove('routeData');

      // Create trip request WITH vehicleId for booking endpoint
      final tripRequest = TripRequest(
        locationData: locationData,
        scheduleData: widget.tripData['scheduleData'],
        passengerData: widget.tripData['passengerData'],
        selectedVehicleId: _selectedVehicle!.vehicle.id,
        conflictingTripId: _selectedVehicle!.isInConflict && 
                         _selectedVehicle!.conflictingTripData != null
                         ? _selectedVehicle!.conflictingTripData!.tripId
                         : null,
      );

      print("Booking trip with vehicle ID: ${_selectedVehicle!.vehicle.id}");
      final response = await ApiService.bookTrip(tripRequest);
      
      print("Booking response received: ${response.success}");

      if (response.success) {
        setState(() {
          _bookedTrip = response.trip;
          _bookingStatus = response.trip?.status ?? 'pending';
          _selectedVehicle = null;
          _estimatedArrivalTime = DateTime.now().add(Duration(minutes: 15));
        });
        
        _showMessage('Trip booked successfully! Status: ${_bookingStatus}');
        
        if (_bookedTrip != null) {
          _startStatusPolling(_bookedTrip!.id);
        }
      } else {
        _showMessage(response.message ?? 'Failed to book trip');
      }
    } catch (e) {
      print('Error booking trip: $e');
      _showMessage('Failed to book trip: ${e.toString()}');
    } finally {
      setState(() => _isBooking = false);
    }
  }

  void _startStatusPolling(int tripId) {
    _statusTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final response = await ApiService.getTripStatus(tripId);
        
        if (response['success'] == true) {
          final status = response['data']?['status'] ?? 'pending';
          print('Trip status updated: $status');
          
          setState(() {
            _bookingStatus = status;
          });
          
          if (status == 'approved') {
            _approvedTime = DateTime.now();
            _estimatedArrivalTime = DateTime.now().add(Duration(minutes: 15));
          }
          
          if (status == 'approved' || status == 'rejected' || status == 'canceled' || status == 'completed') {
            timer.cancel();
            print('Status polling stopped: $status');
          }
        }
      } catch (e) {
        print('Error polling status: $e');
      }
    });
  }

  Future<void> _cancelTrip() async {
    if (_bookedTrip == null) return;

    try {
      setState(() => _isCanceling = true);
      
      final response = await ApiService.cancelTrip(_bookedTrip!.id);
      if (response['success'] == true) {
        _statusTimer?.cancel();
        setState(() {
          _bookingStatus = 'canceled';
        });
        _showMessage('Trip cancelled successfully');
      } else {
        _showMessage(response['message'] ?? 'Failed to cancel trip');
      }
    } catch (e) {
      print('Error canceling trip: $e');
      _showMessage('Failed to cancel trip');
    } finally {
      setState(() => _isCanceling = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showMessage('Cannot make call to $phoneNumber');
    }
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

  Color _getRouteSegmentColor(int segmentIndex) {
    final colors = [
      Colors.blue.withOpacity(0.8),
      Colors.red.withOpacity(0.8),
      Colors.green.withOpacity(0.8),
      Colors.purple.withOpacity(0.8),
      Colors.orange.withOpacity(0.8),
      Colors.teal.withOpacity(0.8),
    ];
    return colors[segmentIndex % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

/*
  Future<void> _onBackPressed() async {
    // If trip is pending/approved, ask for confirmation
    if (_bookedTrip != null && 
        (_bookingStatus == 'pending' || _bookingStatus == 'approved')) {
      final shouldGoBack = await _showBackConfirmation();
      if (!shouldGoBack) return;
    }
    
    // If we have trip data, pass it back
    if (widget.tripData.isNotEmpty) {
      Navigator.of(context).pop(widget.tripData);
    } else {
      Navigator.of(context).pop();
    }
  }
  */
  Future<void> _onBackPressed() async {
    // If trip is booked (pending/approved/completed) -> go back WITHOUT data
    if (_bookedTrip != null && 
        (_bookingStatus == 'pending' || 
        _bookingStatus == 'approved' || 
        _bookingStatus == 'completed'||
        _bookingStatus == 'canceled')) {
      // Navigate directly to CreateTripScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => CreateTripScreen()),
        (Route<dynamic> route) => false, // Remove all routes
      );
      return;
    }
    
    // If no booking yet AND not canceled -> go back WITH data
    if (widget.tripData.isNotEmpty) {
      Navigator.of(context).pop(widget.tripData);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showBackConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Go Back?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You have a trip in progress. Going back will keep your trip details so you can book again if needed.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Stay Here', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Go Back', style: TextStyle(color: Colors.yellow[600])),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMap(),
          _buildHeader(),
          _buildMainPanel(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Row(
          children: [
            GestureDetector(
              //onTap: () => Navigator.pop(context),
              onTap: () => _onBackPressed(),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFF9C80E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_rounded, color: Colors.black, size: 20),
              ),
            ),
            SizedBox(width: 16),
            Text(
              widget.isViewMode ? "Trip Details" : 
                 _bookedTrip != null ? "Trip Status" : "Select Vehicle",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.vehiclereservation',
        ),
        if (_hasRouteData()) _buildRouteLayer(),
        MarkerLayer(markers: _buildRouteMarkers()),
      ],
    );
  }

  bool _hasRouteData() {
    final routeData = widget.tripData['locationData']?['routeData'];
    return routeData != null && routeData['routeSegments'] != null && routeData['routeSegments'].isNotEmpty;
  }

  Widget _buildRouteLayer() {
    final routeData = widget.tripData['locationData']?['routeData'];
    final routeSegments = routeData['routeSegments'] ?? [];
    
    return PolylineLayer(
      polylines: [
        for (int i = 0; i < routeSegments.length; i++)
          Polyline(
            points: _convertCoordinatesToLatLng(routeSegments[i]['points']),
            color: _getRouteSegmentColor(i),
            strokeWidth: 6,
          ),
      ],
    );
  }

  List<LatLng> _convertCoordinatesToLatLng(List<dynamic> coordinates) {
    return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
  }

  List<Marker> _buildRouteMarkers() {
    try {
      final locations = widget.tripData['locationData'];
      final startCoords = locations['startLocation']['coordinates']['coordinates'];
      final endCoords = locations['endLocation']['coordinates']['coordinates'];
      
      final startLatLng = LatLng(startCoords[1], startCoords[0]);
      final endLatLng = LatLng(endCoords[1], endCoords[0]);
      
      return [
        Marker(
          width: 40, height: 40, point: startLatLng,
          child: Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
        Marker(
          width: 40, height: 40, point: endLatLng,
          child: Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  Widget _buildMainPanel() {
  final shouldShowExpanded = _isPanelExpanded && 
      _bookedTrip == null && 
      !widget.isViewMode;

  final panelHeight = shouldShowExpanded
      ? MediaQuery.of(context).size.height * 0.8
      : (_bookedTrip != null && (_bookingStatus == 'pending' || _bookingStatus == 'approved'))
          ? MediaQuery.of(context).size.height * 0.5 // Increased height for status panels
          : MediaQuery.of(context).size.height * 0.4;

  return Positioned(
    bottom: 0, left: 0, right: 0,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: panelHeight,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Only show drag handle for vehicle selection (not for status panels)
          if (_bookedTrip == null && !widget.isViewMode)
            _buildDragHandle(),
          Expanded(child: _buildPanelContent()),
        ],
      ),
    ),
  );
}

  Widget _buildDragHandle() {
  // Don't show drag handle for booked trips (status panels)
  if (_bookedTrip != null || widget.isViewMode) {
    return SizedBox.shrink();
  }
  
  return GestureDetector(
    onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Icon(
        _isPanelExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
        color: Colors.grey[400], size: 24,
      ),
    ),
  );
}

  Widget _buildPanelContent() {
    if (_bookedTrip != null || widget.isViewMode) {
      // Show trip status panels
      switch (_bookingStatus) {
        case 'pending':
          return _buildPendingApprovalPanel();
        case 'approved':
          return _buildApprovedTripPanel();
        case 'completed':
          return _buildCompletedTripPanel();
        case 'canceled':
          return _buildCanceledTripPanel();
        case 'rejected':
          return _buildRejectedTripPanel();
        default:
          return _buildVehicleSelectionContent();
      }
    } else {
      // Show vehicle selection for new trips
      return _buildVehicleSelectionContent();
    }
  }

  Widget _buildVehicleSelectionContent() {
    return Column(
      children: [
        _buildSectionHeader('Available Vehicles', _allVehicles.length),
        Expanded(child: _buildVehicleList(_allVehicles)),
        if (_selectedVehicle != null && !widget.isViewMode) _buildBookButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(List<AvailableVehicle> vehicles) {
    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.car_repair, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text('No vehicles available', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Please try again later', style: TextStyle(color: Colors.grey[600]!, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final isSelected = _selectedVehicle?.vehicle.id == vehicle.vehicle.id;
        return _buildVehicleCard(vehicle, isSelected);
      },
    );
  }

  Widget _buildVehicleCard(AvailableVehicle availableVehicle, bool isSelected) {
  final vehicle = availableVehicle.vehicle;
  final availableSeats = vehicle.seatingAvailability ?? 0;
  
  return Card(
    margin: EdgeInsets.only(bottom: 12),
    color: isSelected ? Colors.yellow[600]!.withOpacity(0.2) : Colors.grey[800],
    child: InkWell(
      onTap: widget.isViewMode ? null : () => setState(() => _selectedVehicle = availableVehicle),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Model + Reg No + Conflict info + Recommendation + Selection
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(vehicle.model ?? 'Unknown Model', 
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                          Text('  '),
                          Text(vehicle.regNo, 
                            style: TextStyle(color: Colors.grey[400], fontSize: 11)
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Conflict info below vehicle details
                      if (availableVehicle.isInConflict)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'At: ${availableVehicle.conflictingTripData!.startTime} ',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'From: ${availableVehicle.conflictingTripData!.startLocation.address} '
                              'To: ${availableVehicle.conflictingTripData!.endLocation.address}',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'To: ${availableVehicle.conflictingTripData!.endLocation.address}',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        )
                    ],
                  ),
                ),
                
                // Right side: Recommendation badge and selection check
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (availableVehicle.isRecommended)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.green, 
                          borderRadius: BorderRadius.circular(3)
                        ),
                        child: Text('R', 
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    if (isSelected) Icon(Icons.check_circle, color: Colors.yellow[600], size: 20),
                  ],
                ),
              ],
            ),
            
            // Recommendation reason
            if (availableVehicle.isRecommended && availableVehicle.recommendationReason.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(availableVehicle.recommendationReason, 
                    style: TextStyle(color: Colors.green, fontSize: 10)),
              ),
            
            // Second row: Distance + Time + Seats
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 12),
                      SizedBox(width: 4),
                      Text('${(availableVehicle.distanceFromStart / 1000).toStringAsFixed(1)} km', 
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                      SizedBox(width: 12),
                      Icon(Icons.access_time, color: Colors.grey, size: 12),
                      SizedBox(width: 4),
                      Text('${availableVehicle.estimatedArrivalTime.toStringAsFixed(0)} min', 
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.grey, size: 12),
                      SizedBox(width: 4),
                      Text('${availableSeats > 0 ? availableSeats : 0} seats available', 
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Driver info (only if exists)
            if (vehicle.assignedDriverPrimaryName != null)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey, size: 10),
                    SizedBox(width: 4),
                    Text('Driver: ${vehicle.assignedDriverPrimaryName!}', 
                        style: TextStyle(color: Colors.grey[300], fontSize: 10)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDriverInfo(String role, String name, String phone) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$role: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text(name, style: TextStyle(color: Colors.white, fontSize: 14)),
          Spacer(),
          IconButton(
            icon: Icon(Icons.phone, color: Colors.yellow[600], size: 18),
            onPressed: () => _makeCall(phone),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    if (_bookedTrip != null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: (_isBooking || _bookedTrip != null) ? null : _bookTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: (_isBooking || _bookedTrip != null) 
              ? Colors.grey 
              : Colors.yellow[600],
          foregroundColor: Colors.black,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isBooking
            ? SizedBox(
                height: 20, width: 20, 
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text('Book Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPendingApprovalPanel() {
  final estimatedArrival = _estimatedArrivalTime ?? DateTime.now().add(Duration(minutes: 15));
  
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule, color: Colors.yellow[600], size: 54),
        SizedBox(height: 12),
        Text(
          'Please wait! Your ride has been submitted for approval.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        LinearProgressIndicator(
          backgroundColor: Colors.grey[700],
          color: Colors.yellow[600],
        ),
        SizedBox(height: 16),
        Card(
          color: Colors.grey[800],
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                _buildTripDetailRow('Trip ID', '#${_bookedTrip?.id ?? 'N/A'}'),
                SizedBox(height: 6),
                _buildTripDetailRow('Estimated Arrival', _formatTime(estimatedArrival)),
                SizedBox(height: 6),
                _buildTripDetailRow('Status', 'Pending Approval', isStatus: true),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        if (!widget.isViewMode)
          Container(
            width: double.infinity, // Make container full width
            child: ElevatedButton(
              onPressed: _isCanceling ? null : _cancelTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44), // Full width button
              ),
              child: _isCanceling 
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Cancel Trip',
                      style: TextStyle(fontSize: 14),
                    ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildApprovedTripPanel() {
    final estimatedArrival = _estimatedArrivalTime ?? DateTime.now().add(Duration(minutes: 15));
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text('Your ride will arrive at ${_formatTime(estimatedArrival)}',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Card(
            color: Colors.grey[800],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTripDetailRow('Driver', _bookedTrip?.driverName ?? 'Not assigned'),
                  SizedBox(height: 8),
                  _buildTripDetailRow('Vehicle', '${_bookedTrip?.vehicleModel ?? 'Unknown'} (${_bookedTrip?.vehicleRegNo ?? 'Unknown'})'),
                  SizedBox(height: 8),
                  _buildTripDetailRow('Driver Contact', _bookedTrip?.driverPhone ?? 'Not assigned'),
                  SizedBox(height: 8),
                  _buildTripDetailRow('Status', 'Approved', isStatus: true),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _makeCall(_bookedTrip?.driverPhone ?? ''),
                icon: Icon(Icons.phone, size: 20),
                label: Text('Call Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[600],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              /*if (!widget.isViewMode)
                ElevatedButton.icon(
                  onPressed: _isCanceling ? null : _cancelTrip,
                  icon: Icon(Icons.cancel, size: 20),
                  label: Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),*/
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTripPanel() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text('Trip Completed',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            color: Colors.grey[800],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTripDetailRow('Driver', _bookedTrip?.driverName ?? 'Not assigned'),
                  SizedBox(height: 8),
                  _buildTripDetailRow('Vehicle', '${_bookedTrip?.vehicleModel ?? 'Unknown'} (${_bookedTrip?.vehicleRegNo ?? 'N/A'})'),
                  SizedBox(height: 8),
                  _buildTripDetailRow('Trip Date', _bookedTrip?.createdAt != null 
                    ? _formatDate(_bookedTrip!.createdAt!) 
                    : 'N/A'),
                  SizedBox(height: 8),
                  _buildTripDetailRow('Status', 'Completed', isStatus: true),
                  if (_bookedTrip?.cost != null && _bookedTrip!.cost! > 0) ...[
                    SizedBox(height: 8),
                    _buildTripDetailRow('Cost', 'Rs. ${_bookedTrip!.cost!.toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => CreateTripScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[600],
              foregroundColor: Colors.black,
            ),
            child: Text('Back to Trips'),
          ),
        ],
      ),
    );
  }

  Widget _buildCanceledTripPanel() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text('Trip Canceled',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This trip has been canceled.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            //onPressed: () => Navigator.pop(context),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => CreateTripScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[600],
              foregroundColor: Colors.black,
            ),
            child: Text('Book New Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedTripPanel() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 64),
          SizedBox(height: 16),
          Text('Trip Rejected',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Your trip request was not approved by the administrator.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => CreateTripScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[600],
              foregroundColor: Colors.black,
            ),
            child: Text('Book New Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(width: 8),
        Expanded(
          child: Text(value,
            style: TextStyle(
              color: isStatus ? _getStatusColor(value.toLowerCase()) : Colors.white,
              fontSize: 14,
              fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending approval': return Colors.yellow[600]!;
      case 'approved': return Colors.green;
      case 'completed': return Colors.blue;
      case 'canceled': return Colors.red;
      case 'rejected': return Colors.orange;
      default: return Colors.white;
    }
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFF9C80E)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFF9C80E)),
                SizedBox(height: 16),
                Text(
                  widget.isViewMode ? 'Loading trip details...' : 'Loading available vehicles...',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}