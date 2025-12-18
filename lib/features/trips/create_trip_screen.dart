import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/mixins/realtime_screen_mixin.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/schedule_passenger_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/nominatim_search_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/osrm_route_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/ws/namespace_websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/geocode_helper.dart';
import 'dart:math' as math;

class CreateTripScreen extends StatefulWidget {
  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> with RealtimeScreenMixin {
  @override
  String get namespace => 'trips';
  final MapController mapController = MapController();

  List<RouteStop> stops = [
    RouteStop(controller: TextEditingController(), type: StopType.start),
    RouteStop(controller: TextEditingController(), type: StopType.end),
  ];

  List<Marker> markers = [];
  List<Polyline> routeSegments = [];
  LatLng currentPos = LatLng(6.9271, 79.8612);
  bool _isSelectingOnMap = false;
  LatLng? _currentLocationMarker;
  bool _isLoading = false;
  RouteStop? _currentSelectingStop;
  
  // New state variables for panel control
  bool _isPanelExpanded = false;
  bool _isPanelVisible = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    try {
      final token = await SecureStorageService().accessToken;
      final user = StorageService.userData;
      if (token != null && user != null) {
        await NamespaceWebSocketManager().initializeNamespace(namespace, token, user.id.toString());
      }
    } catch (e) {
      print('Create Trip WebSocket initialization error: $e');
    }
  }

  @override
  void handleScreenRefresh(Map<String, dynamic> data) {
    // Handle realtime trip creation updates, vehicle availability
    final eventType = data['type'];
    if (eventType == 'vehicle-availability-changed') {
      // Refresh vehicle availability
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePanelExpansion() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
    });
  }

  void _togglePanelVisibility() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
  }

  // Auto-hide panel when location selection starts
  void _autoHidePanel() {
    if (_isPanelVisible) {
      setState(() {
        _isPanelVisible = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Please enable location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          _showMessage('Location permission is required');
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        currentPos = LatLng(pos.latitude, pos.longitude);
        _currentLocationMarker = currentPos;
      });

      mapController.move(currentPos, 14);
    } catch (e) {
      print("Error getting location: $e");
      _showMessage('Unable to get current location');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _autoCalculateRoute() async {
    // Only auto-calculate if we have at least 2 stops with coordinates
    final stopsWithCoordinates = stops.where((stop) => 
      stop.coordinates != null && stop.controller.text.isNotEmpty
    ).length;
    
    if (stopsWithCoordinates >= 2) {
      // Small delay to ensure UI updates first
      await Future.delayed(Duration(milliseconds: 300));
      _calculateRoute();
    }
  }

  void _useCurrentLocation(RouteStop stop) async {
  try {
    setState(() => _isLoading = true);
    
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final currentLatLng = LatLng(pos.latitude, pos.longitude);
    
    final results = await NominatimService.reverseGeocode(pos.latitude, pos.longitude);
    if (results.isNotEmpty && results["data"]["display_name"] != null) {
      stop.controller.text = results["data"]["display_name"];
    } else {
      stop.controller.text = "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
    }

    stop.coordinates = currentLatLng; // Set coordinates
    _addOrUpdateMarkerForStop(stop, currentLatLng);
    mapController.move(currentLatLng, 15);
    
    setState(() {
      _currentLocationMarker = currentLatLng;
    });

    // Auto-calculate route after setting current location
    _autoCalculateRoute();
  } catch (e) {
    print("Error getting current location: $e");
    _showMessage('Error getting current location');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _selectPlace(RouteStop stop, dynamic place) async {
    try {
      LatLng selected = GeoHelper.jsonToLatLng(place);
      stop.controller.text = place["display_name"] ?? 'Selected Location';
      stop.coordinates = selected; // Set coordinates
      _addOrUpdateMarkerForStop(stop, selected);
      mapController.move(selected, 15);

      // Auto-calculate route after selecting place
    _autoCalculateRoute();
    } catch (e) {
      print("Error selecting place: $e");
    }
  }

  void _startMapSelection(RouteStop stop) {
    setState(() {
      _isSelectingOnMap = true;
      _currentSelectingStop = stop;
    });
    
    // Auto-hide panel when starting map selection
    _autoHidePanel();
    
    _showMessage('Drag the marker or tap on map to set location');
  }

  void _stopMapSelection() {
    setState(() {
      _isSelectingOnMap = false;
      _currentSelectingStop = null;
    });
  }

  Future<void> _setLocationFromCoordinates(LatLng position, RouteStop stop) async {
  try {
    setState(() => _isLoading = true);
    
    stop.controller.text = "Getting address...";
    
    final results = await NominatimService.reverseGeocode(position.latitude, position.longitude);
    if (results.isNotEmpty && results["data"]["display_name"] != null) {
      stop.controller.text = results["data"]["display_name"];
    } else {
      stop.controller.text = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
    }

    stop.coordinates = position; // Set coordinates
    _addOrUpdateMarkerForStop(stop, position); 

    // Auto-calculate route after setting location
    _autoCalculateRoute();   
  } catch (e) {
    print("Error reverse geocoding: $e");
    stop.controller.text = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
    stop.coordinates = position; // Set coordinates even if reverse geocoding fails
    _addOrUpdateMarkerForStop(stop, position);

    // Still try to auto-calculate route
    _autoCalculateRoute();
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _addOrUpdateMarkerForStop(RouteStop stop, LatLng pos) {
  // Generate a unique key that includes the stop's unique identifier
  final stopIndex = stops.indexOf(stop);
  final markerKey = ValueKey('${stop.type}_${stop.controller.hashCode}_$stopIndex');
  
  // Remove existing marker for this stop
  markers.removeWhere((m) {
    final existingKey = m.key as ValueKey?;
    return existingKey?.value.toString().contains(stop.type.toString()) == true &&
           existingKey?.value.toString().contains(stop.controller.hashCode.toString()) == true;
  });

  markers.add(
    Marker(
      key: markerKey,
      point: pos,
      width: 50,
      height: 50,
      child: GestureDetector(
        onPanUpdate: (details) {
          final pixelPoint = mapController.camera.project(pos);
          final newPixelPoint = math.Point<double>(
            pixelPoint.x + details.delta.dx,
            pixelPoint.y + details.delta.dy,
          );
          final newPoint = mapController.camera.unproject(newPixelPoint);
          _onMarkerDragEnd(stop, newPoint);
        },
        child: Icon(
          Icons.location_on,
          color: _getMarkerColor(stop.type),
          size: 50,
        ),
      ),
    ),
  );

  setState(() {});
}

  void _onMarkerDragEnd(RouteStop stop, LatLng newPosition) {
    _setLocationFromCoordinates(newPosition, stop);
  }

  Color _getMarkerColor(StopType type) {
    switch (type) {
      case StopType.start:
        return Colors.green;
      case StopType.end:
        return Colors.red;
      case StopType.waypoint:
        return Colors.orange;
    }
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

  void _clearField(RouteStop stop) {
    stop.controller.clear();
    stop.coordinates = null; // Clear coordinates too
    final stopIndex = stops.indexOf(stop);
    final markerKey = ValueKey('${stop.type}_$stopIndex');
    markers.removeWhere((m) => m.key == markerKey);
    setState(() {});
    
    // If we had a route calculated, clear it
    if (routeSegments.isNotEmpty) {
      routeSegments.clear();
      setState(() {});
    }

    _autoCalculateRoute();
  }

  Future<void> _calculateRoute() async {
  if (_isLoading) return;
  
  try {
    setState(() => _isLoading = true);
    
    List<LatLng> points = [];
    List<String> invalidStops = [];

    routeSegments.clear();

    for (var i = 0; i < stops.length; i++) {
      var stop = stops[i];
      if (stop.controller.text.trim().isEmpty) {
        if (stop.type != StopType.waypoint) {
          invalidStops.add(_getStopName(stop.type));
        }
        continue;
      }

      try {
        final query = "${stop.coordinates?.latitude.toStringAsFixed(6)}, ${stop.coordinates?.longitude.toStringAsFixed(6)}";
        //final results = await NominatimService.search(stop.controller.text);
        final results = await NominatimService.search(query);
        if (results.isNotEmpty) {
          final latLng = GeoHelper.jsonToLatLng(results.first);
          points.add(latLng);
          stop.coordinates = latLng; // Set coordinates
          _addOrUpdateMarkerForStop(stop, latLng);
        } else {
          invalidStops.add(_getStopName(stop.type));
        }
      } catch (e) {
        invalidStops.add(_getStopName(stop.type));
      }
    }

    // ... rest of the method remains the same
    if (invalidStops.isNotEmpty) {
        _showMessage('Invalid locations: ${invalidStops.join(', ')}');
        return;
      }

      if (points.length < 2) {
        _showMessage('Please enter at least 2 valid locations');
        return;
      }

      for (int i = 0; i < points.length - 1; i++) {
        try {
          final segmentPoints = await OSRMService.getRoute([points[i], points[i + 1]]);
          if (segmentPoints.isNotEmpty) {
            routeSegments.add(
              Polyline(
                points: segmentPoints,
                color: _getRouteSegmentColor(i),
                strokeWidth: 5,
              ),
            );
          }
        } catch (e) {
          print("Error calculating segment $i: $e");
        }
      }

      _fitBounds(points);
      
      //_showMessage('Route calculated successfully!');
  } catch (e) {
    print("Error calculating route: $e");
    _showMessage('Error calculating route');
  } finally {
    setState(() => _isLoading = false);
  }
}
  
  String _getStopName(StopType type) {
    switch (type) {
      case StopType.start:
        return 'Start';
      case StopType.end:
        return 'Destination';
      case StopType.waypoint:
        return 'Stop';
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: EdgeInsets.all(100),
      ),
    );
  }

  void _addWaypoint() {
    if (stops.length >= 6) {
      _showMessage('Maximum 6 stops allowed');
      return;
    }
    
    setState(() {
      stops.insert(
        stops.length - 1,
        RouteStop(controller: TextEditingController(), type: StopType.waypoint),
      );
    });
  }

  void _removeWaypoint(int index) {
    if (stops[index].type == StopType.waypoint) {
      _clearField(stops[index]);
      setState(() => stops.removeAt(index));

      // Re-index and update all markers after removal
      _updateAllMarkers();
    }
  }

  void _updateAllMarkers() {
    markers.clear();
    
    for (var i = 0; i < stops.length; i++) {
      var stop = stops[i];
      if (stop.coordinates != null) {
        _addOrUpdateMarkerForStop(stop, stop.coordinates!);
      }
    }
    
    setState(() {});
  }

  /*
  void _proceedToNext() {
  if (_isLoading) return;
  
  if (stops[0].controller.text.isEmpty || stops.last.controller.text.isEmpty) {
    _showMessage('Please enter start and destination locations');
    return;
  }

  if (routeSegments.isEmpty) {
    _showMessage('Please calculate route first');
    return;
  }

  // Prepare location data to pass to next screen
  final locationData = {
    'startLocation': {
      'address': stops[0].controller.text,
      'coordinates': stops[0].coordinates?.toJson(), // Use the coordinates property
    },
    'endLocation': {
      'address': stops.last.controller.text,
      'coordinates': stops.last.coordinates?.toJson(), // Use the coordinates property
    },
    'intermediateStops': stops.sublist(1, stops.length - 1).map((stop) => {
      'address': stop.controller.text,
      'coordinates': stop.coordinates?.toJson(), // Use the coordinates property
      'type': stop.type.toString(),
    }).toList(),
    'totalStops': stops.length,
  };

  // Navigate to SchedulePassengersScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SchedulePassengersScreen(
        locationData: locationData,
      ),
    ),
  );
}
  */
  void _proceedToNext() {
  if (_isLoading) return;
  
  if (stops[0].controller.text.isEmpty || stops.last.controller.text.isEmpty) {
    _showMessage('Please enter start and destination locations');
    return;
  }

  if (routeSegments.isEmpty) {
    _showMessage('Please calculate route first');
    return;
  }

  // Prepare location data to pass to next screen
  final locationData = {
    'startLocation': {
      'address': stops[0].controller.text,
      'coordinates': stops[0].coordinates?.toJson(),
    },
    'endLocation': {
      'address': stops.last.controller.text,
      'coordinates': stops.last.coordinates?.toJson(),
    },
    'intermediateStops': stops.sublist(1, stops.length - 1).map((stop) => {
      'address': stop.controller.text,
      'coordinates': stop.coordinates?.toJson(),
      'type': stop.type.toString(),
    }).toList(),
    'totalStops': stops.length,
    // Add route data
    'routeData': {
      'routeSegments': routeSegments.map((segment) => {
        'points': segment.points.map((point) => [point.longitude, point.latitude]).toList(),
        'color': segment.color.value, // Store color as integer
        'strokeWidth': segment.strokeWidth,
      }).toList(),
    },
  };

  // Navigate to SchedulePassengersScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SchedulePassengersScreen(
        locationData: locationData,
      ),
    ),
  );
}

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMap(),
                      if (_isPanelVisible) _buildStopBox(),
                      _buildFloatingButtons(),
                      _buildPanelControlButtons(),
                    ],
                  ),
                )
              ],
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 20),
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
            //onTap: () => Navigator.pop(context),
            onTap: () {
              // Navigate to home screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
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
            "Locations",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentPos,
        initialZoom: 14,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
        onTap: (tapPosition, latLng) {
          if (_isSelectingOnMap && _currentSelectingStop != null) {
            _setLocationFromCoordinates(latLng, _currentSelectingStop!);
            _stopMapSelection();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.vehiclereservation',
        ),
        if (routeSegments.isNotEmpty)
          PolylineLayer(
            polylines: routeSegments,
          ),
        MarkerLayer(markers: markers),
        if (_currentLocationMarker != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocationMarker!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStopBox() {
    final visibleStops = _isPanelExpanded ? stops : stops.take(2).toList();
    final panelHeight = _isPanelExpanded 
        ? MediaQuery.of(context).size.height * 0.6
        : stops.length > 2 ? 245.0 : 200.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: panelHeight,
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  children: [
                    ...visibleStops.asMap().entries.map((e) => _buildStopInput(e.key, e.value)),
                    if (!_isPanelExpanded && stops.length > 2) 
                      _buildMoreStopsIndicator(),
                    if (stops.length < 6) _buildAddStopButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreStopsIndicator() {
    return Padding(
      padding: EdgeInsets.only(top: 0),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 20),
            SizedBox(width: 8),
            Text(
              '${stops.length - 2} more stops',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelControlButtons() {
    return Positioned(
      top: _isPanelVisible ? (_isPanelExpanded ? MediaQuery.of(context).size.height * 0.6 : 250) + 10 : 30,
      right: 10,
      child: Column(
        children: [
          // Expand/Collapse button
          if (_isPanelVisible)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF9C80E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isPanelExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: _togglePanelExpansion,
                tooltip: _isPanelExpanded ? 'Collapse' : 'Expand',
              ),
            ),
          // Show/Hide panel button
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF9C80E),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPanelVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
                size: 20,
              ),
              onPressed: _togglePanelVisibility,
              tooltip: _isPanelVisible ? 'Hide Panel' : 'Show Panel',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopInput(int index, RouteStop stop) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: TypeAheadField(
                  controller: stop.controller,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: _getHintText(stop.type),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        prefixIcon: GestureDetector(
                          onTap: () {
                            // Auto-hide panel when location icon is clicked
                            _autoHidePanel();
                            _startMapSelection(stop);
                          },
                          child: Icon(
                            Icons.add_location_alt,
                            color: _getMarkerColor(stop.type),
                            size: 20,
                          ),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (stop.controller.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                                onPressed: () => _clearField(stop),
                                tooltip: 'Clear',
                              ),
                            IconButton(
                              icon: Icon(Icons.my_location, color: Color(0xFFF9C80E), size: 18),
                              onPressed: () {
                                // Auto-hide panel when current location icon is clicked
                                _autoHidePanel();
                                _useCurrentLocation(stop);
                              },
                              tooltip: 'Use current location',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  suggestionsCallback: (value) async {
                    if (value.length < 2) return [];
                    try {
                      final results = await NominatimService.search(value);
                      return results;
                    } catch (e) {
                      print("Search error: $e");
                      return [];
                    }
                  },
                  itemBuilder: (context, item) {
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.location_on, color: Color(0xFFF9C80E), size: 20),
                        title: Text(
                          item["display_name"] ?? 'Unknown location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: item["type"] != null ? Text(
                          'Type: ${item["type"]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ) : null,
                        dense: true,
                      ),
                    );
                  },
                  onSelected: (suggestion) => _selectPlace(stop, suggestion),
                ),
              ),
            ),
            if (stop.type == StopType.waypoint)
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red, size: 22),
                onPressed: () => _removeWaypoint(index),
                tooltip: 'Remove stop',
              ),
          ],
        ),
        if (index < stops.length - 1) SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAddStopButton() {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: _addWaypoint,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Color(0xFFF9C80E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFFF9C80E)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        ),
        icon: Icon(Icons.add, size: 18),
        label: Text(
          'Add Stop',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 10,
      left: 10,
      child: Column(
        children: [
          /*
          FloatingActionButton(
            heroTag: 'route_btn',
            backgroundColor: Color(0xFFF9C80E),
            onPressed: _calculateRoute,
            child: Icon(Icons.route, color: Colors.black, size: 24),
          ),
          */
          SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'location_btn',
            backgroundColor: Color(0xFFF9C80E),
            onPressed: _getCurrentLocation,
            child: Icon(Icons.my_location, color: Colors.black, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: ElevatedButton(
        onPressed: _proceedToNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF9C80E),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          'Confirm Route',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getHintText(StopType type) {
    switch (type) {
      case StopType.start:
        return 'Enter start location';
      case StopType.waypoint:
        return 'Add stop location';
      case StopType.end:
        return 'Enter destination';
    }
  }

}

class RouteStop {
  TextEditingController controller;
  StopType type;
  LatLng? coordinates;

  RouteStop({
    required this.controller, 
    required this.type,
    this.coordinates,
  });
}

extension LatLngExtension on LatLng {
  Map<String, double> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

enum StopType { start, waypoint, end }
