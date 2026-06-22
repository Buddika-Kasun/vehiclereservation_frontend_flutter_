import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/optional_permission_manager%20copy.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_details_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// Import new WebSocket structure
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/trip_handler.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/user_search_dialog.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';

class ExceedTripDetailsScreen extends StatefulWidget {
  final UserRole userRole;
  final int tripId;
  final bool fromConflictNavigation;
  final bool fromInstanceNavigation;

  const ExceedTripDetailsScreen({
    Key? key,
    required this.userRole,
    required this.tripId,
    this.fromConflictNavigation = false,
    this.fromInstanceNavigation = false,
  }) : super(key: key);

  @override
  _ExceedTripDetailsScreenState createState() =>
      _ExceedTripDetailsScreenState();
}

class _ExceedTripDetailsScreenState extends State<ExceedTripDetailsScreen> {
  // WebSocket managers
  final WebSocketManager _webSocketManager = WebSocketManager();
  final TripHandler _tripHandler = TripHandler();

  TripDetails? _tripDetails;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNotificationShowing = false;

  // Map related variables
  List<Marker> _markers = [];
  List<Polyline> _routeSegments = [];
  LatLngBounds? _mapBounds;

  // WebSocket connection state
  bool _isConnected = false;
  bool _isInitializing = false;
  Timer? _debounceTimer;

  // Add these helper methods
  String _getTripTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'emergency':
        return 'Emergency';
      case 'fixed_rate':
        return 'Fixed Rate';
      case 'safety_approval':
        return 'Safety Approval';
      default:
        return type;
    }
  }

  Color _getTripTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return Colors.blue;
      case 'emergency':
        return Colors.red;
      case 'fixed_rate':
        return Colors.green;
      case 'safety_approval':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTripTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return Icons.trip_origin;
      case 'emergency':
        return Icons.error;
      case 'fixed_rate':
        return Icons.monetization_on;
      case 'safety_approval':
        return Icons.security;
      default:
        return Icons.trip_origin;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cleanupWebSocket();
    super.dispose();
  }

  Future<void> _initializeWebSocket() async {
    try {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      // Get token and userId from storage
      final token = await _getToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
        return;
      }

      // Initialize WebSocket manager
      _webSocketManager.initialize(token: token, userId: userId);

      // Initialize trip handler
      await _tripHandler.initialize(token: token, userId: userId);

      // Connect to trips namespace
      await _webSocketManager.connectToNamespace('/trips');

      // Set up trip handler callback for refresh events
      _tripHandler.onTripUpdate = (update) {
        _handleTripUpdate(update);
      };

      // Set up connection listener
      _webSocketManager.addConnectionListener('/trips', (isConnected) {
        if (kDebugMode) {
          print('🔌 TripDetailsScreen connection: $isConnected');
        }
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
            _isInitializing = false;
          });
        }
      });

      // Set up message listener for direct messages
      _webSocketManager.addMessageListener('/trips', (message) {
        _handleWebSocketMessage(message);
      });

      if (mounted) {
        setState(() {
          _isConnected = _webSocketManager.isNamespaceConnected('/trips');
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TripDetailsScreen WebSocket error: $e');
      }
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isInitializing = false;
        });
      }
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final event = message['event']?.toString() ?? '';
    final data = message['data'];

    if (kDebugMode) {
      print('📨 TripDetailsScreen received event: $event');
    }

    // Handle refresh events
    if (event == 'refresh') {
      _handleRefreshEvent(data);
    }
  }

  void _handleTripUpdate(Map<String, dynamic> update) {
    final type = update['type']?.toString() ?? '';
    final scope = update['scope']?.toString() ?? '';
    final tripId = update['tripId'];

    if (kDebugMode) {
      print('🔄 Trip update received: $type, scope: $scope, tripId: $tripId');
    }

    // Check if this update is for the current trip
    if (tripId != null && tripId == widget.tripId) {
      _debounceRefresh();
    }
    // Also refresh for general trip updates that might affect this screen
    else if (scope == 'TRIPS' || scope == 'ALL') {
      _debounceRefresh();
    }
  }

  void _handleRefreshEvent(Map<String, dynamic> data) {
    final scope = data['scope']?.toString() ?? 'ALL';
    final tripId = data['tripId'];

    if (kDebugMode) {
      print('🔄 Refresh event received, scope: $scope, tripId: $tripId');
    }

    // Check if this update is for the current trip
    if (tripId != null && tripId == widget.tripId) {
      _debounceRefresh();
    }
    // Also refresh for general trip updates
    else if (scope == 'TRIPS' || scope == 'ALL') {
      _debounceRefresh();
    }
  }

  void _debounceRefresh() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadTripDetails();
      }
    });
  }

  Future<void> _loadTripDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await ApiService.getTripById(widget.tripId);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _tripDetails = TripDetails.fromJson(response['data']);
        });

        // Initialize map after loading trip details
        _initializeMap();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch trip details');
      }
    } catch (e) {
      print('Error loading trip details: $e');
      setState(() {
        _errorMessage = 'Error loading trip details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeMap() {
    if (_tripDetails?.details.route.hasRoute == true) {
      // Check if we have valid route data
      final hasValidCoordinates =
          _tripDetails?.details.route.coordinates.start.latitude != null &&
          _tripDetails?.details.route.coordinates.start.longitude != null &&
          _tripDetails?.details.route.coordinates.end.latitude != null &&
          _tripDetails?.details.route.coordinates.end.longitude != null;

      if (hasValidCoordinates) {
        _setupMapMarkersAndRoute();
      }
    }
  }

  void _setupMapMarkersAndRoute() {
    try {
      // Clear existing markers and routes
      _markers.clear();
      _routeSegments.clear();

      // Add start marker
      if (_tripDetails?.details.route.coordinates.start != null) {
        final start = _tripDetails!.details.route.coordinates.start;
        if (start.latitude != 0 && start.longitude != 0) {
          _markers.add(
            _createMarkerWithAddress(
              LatLng(start.latitude, start.longitude),
              Icons.location_on,
              Colors.green,
              start.address,
            ),
          );
        }
      }

      // Add intermediate stops markers
      for (var stop in _tripDetails?.details.route.stops.intermediate ?? []) {
        if (stop.latitude != 0 && stop.longitude != 0) {
          _markers.add(
            _createMarkerWithAddress(
              LatLng(stop.latitude, stop.longitude),
              Icons.location_on,
              Colors.orange,
              '(${stop.order}) ${stop.address}',
            ),
          );
        }
      }

      // Add end marker
      if (_tripDetails?.details.route.coordinates.end != null) {
        final end = _tripDetails!.details.route.coordinates.end;
        if (end.latitude != 0 && end.longitude != 0) {
          _markers.add(
            _createMarkerWithAddress(
              LatLng(end.latitude, end.longitude),
              Icons.location_on,
              Colors.red,
              end.address,
            ),
          );
        }
      }

      // Create route segments from rawData
      if (_tripDetails?.details.route.rawData != null &&
          _tripDetails!.details.route.rawData!.routeSegments.isNotEmpty) {
        final rawData = _tripDetails!.details.route.rawData!;
        for (var segment in rawData.routeSegments) {
          if (segment.points.isNotEmpty) {
            try {
              final points = segment.points
                  .map((point) {
                    if (point.length >= 2) {
                      return LatLng(point[1], point[0]);
                    }
                    return LatLng(0, 0);
                  })
                  .where((point) => point.latitude != 0 && point.longitude != 0)
                  .toList();

              if (points.isNotEmpty) {
                _routeSegments.add(
                  Polyline(
                    points: points,
                    color: Color(segment.color),
                    strokeWidth: segment.strokeWidth.toDouble(),
                  ),
                );
              }
            } catch (e) {
              print('Error processing route segment: $e');
            }
          }
        }
      }

      // Calculate bounds
      _calculateSimpleBounds();
    } catch (e) {
      print('Error setting up map: $e');
    }
  }

  void _calculateSimpleBounds() {
    if (_markers.isEmpty && _routeSegments.isEmpty) {
      setState(() {
        _mapBounds = null;
      });
      return;
    }

    List<LatLng> allPoints = [];

    // Add marker points
    for (var marker in _markers) {
      if (marker.point.latitude != 0 && marker.point.longitude != 0) {
        allPoints.add(marker.point);
      }
    }

    // Add route points
    for (var route in _routeSegments) {
      allPoints.addAll(
        route.points.where(
          (point) => point.latitude != 0 && point.longitude != 0,
        ),
      );
    }

    if (allPoints.isEmpty) {
      setState(() {
        _mapBounds = null;
      });
      return;
    }

    // Calculate bounds
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Calculate span
    double latSpan = maxLat - minLat;
    double lngSpan = maxLng - minLng;

    // Ensure minimum span for visibility
    double minSpan = 0.01; // ~1km
    if (latSpan < minSpan) {
      double padding = (minSpan - latSpan) / 2;
      minLat -= padding;
      maxLat += padding;
    }
    if (lngSpan < minSpan) {
      double padding = (minSpan - lngSpan) / 2;
      minLng -= padding;
      maxLng += padding;
    }

    // Add small padding
    double padding = 0.005;

    setState(() {
      _mapBounds = LatLngBounds(
        LatLng(minLat - padding, minLng - padding),
        LatLng(maxLat + padding, maxLng + padding),
      );
    });
  }

  Marker _createMarkerWithAddress(
    LatLng point,
    IconData icon,
    Color color,
    String address,
  ) {
    return Marker(
      point: point,
      width: 70, // Increased width for tooltip
      height: 80, // Increased height for tooltip
      child: GestureDetector(
        onTap: () {
          if (_isNotificationShowing) return;
          // This will show at fixed position from top with fixed height
          // Set flag to true
          setState(() {
            _isNotificationShowing = true;
          });

          final screenHeight = MediaQuery.of(context).size.height;

          ScaffoldMessenger.of(context)
              .showSnackBar(
                SnackBar(
                  content: Container(
                    height: 60, // FIXED HEIGHT
                    child: SingleChildScrollView(
                      child: Text(
                        address,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  backgroundColor: const Color.fromARGB(242, 66, 66, 66),
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: screenHeight - 170, // Fixed 150px from top
                    left: 2,
                    right: 2,
                  ),
                ),
              )
              .closed
              .then((reason) {
                // When snackbar is closed, reset the flag
                if (mounted) {
                  setState(() {
                    _isNotificationShowing = false;
                  });
                }
              });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Address tooltip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 180),
                child: Text(
                  _getShortAddress(address),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 4),
            // Marker icon
            Icon(icon, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  String _getShortAddress(String fullAddress) {
    // Extract the first meaningful part of the address
    final parts = fullAddress.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    return fullAddress;
  }

  double _calculateOptimalZoom() {
    if (_markers.isEmpty && _routeSegments.isEmpty) return 12.0;

    // Collect all points
    List<LatLng> allPoints = [];

    // Add markers
    for (var marker in _markers) {
      if (marker.point.latitude != 0 && marker.point.longitude != 0) {
        allPoints.add(marker.point);
      }
    }

    // Add route points
    for (var route in _routeSegments) {
      allPoints.addAll(
        route.points.where(
          (point) => point.latitude != 0 && point.longitude != 0,
        ),
      );
    }

    if (allPoints.isEmpty) return 12.0;

    // Calculate bounds
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Calculate span in degrees
    double latSpan = maxLat - minLat;
    double lngSpan = maxLng - minLng;

    // Convert to meters (approximate)
    // 1 degree latitude ≈ 111 km, 1 degree longitude ≈ 111 km * cos(latitude)
    double latSpanMeters = latSpan * 111000;
    double lngSpanMeters = lngSpan * 111000 * cos(minLat * 3.14159265 / 180);

    // Use the larger span
    double maxSpanMeters = max(latSpanMeters, lngSpanMeters);

    // Calculate zoom level based on span
    // This is a simple approximation - adjust values as needed
    if (maxSpanMeters < 500) return 16.0; // < 500m
    if (maxSpanMeters < 1000) return 15.0; // < 1km
    if (maxSpanMeters < 2000) return 14.0; // < 2km
    if (maxSpanMeters < 5000) return 13.0; // < 5km
    if (maxSpanMeters < 10000) return 12.0; // < 10km
    if (maxSpanMeters < 20000) return 11.0; // < 20km
    if (maxSpanMeters < 50000) return 10.0; // < 50km
    if (maxSpanMeters < 100000) return 9.0; // < 100km
    return 8.0; // > 100km
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Clean the phone number
      String cleanedNumber = phoneNumber.trim();

      // Validate phone number format
      if (cleanedNumber.isEmpty) {
        _showSnackBar('Phone number is empty', Colors.red);
        return;
      }

      // Check if we have permission first
      final hasPermission =
          await OptionalPermissionManager.requestPhonePermission(
            context: context,
            rationaleMessage: 'Phone permission is required to make calls',
          );

      if (!hasPermission) {
        _showSnackBar('Cannot make call without permission', Colors.red);
        return;
      }

      // Create URL with proper format
      final url = 'tel:$cleanedNumber';
      final uri = Uri.parse(url);

      print('📞 Attempting to call: $cleanedNumber');
      print('📞 URL: $url');

      // Check if we can launch
      bool canLaunch = await canLaunchUrl(uri);
      print('📞 Can launch URL: $canLaunch');

      if (canLaunch) {
        await launchUrl(uri);
        print('📞 Launched dialer successfully');
      } else {
        // Fallback: Try to open dialer with number manually
        print('📞 canLaunchUrl returned false, trying alternative');
        await _launchDialerFallback(cleanedNumber);
      }
    } catch (e, stackTrace) {
      print('❌ Error making call: $e');
      print('❌ Stack trace: $stackTrace');
      _showSnackBar('Unable to make call: ${e.toString()}', Colors.red);
    }
  }

  // Alternative method for opening dialer
  Future<void> _launchDialerFallback(String phoneNumber) async {
    try {
      // Try different URL formats
      final String url = 'tel:$phoneNumber';
      final Uri uri = Uri.parse(url);

      // Try launching directly without checking first
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('❌ Fallback also failed: $e');

      // Show alternative options
      if (context.mounted) {
        await _showNoDialerDialog(context, phoneNumber);
      }
    }
  }

  // Dialog when no dialer is found
  Future<void> _showNoDialerDialog(
    BuildContext context,
    String phoneNumber,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cannot Make Call'),
          content: Text(
            'No phone app found to make calls.\n\n'
            'Phone number: $phoneNumber\n\n'
            'You can manually dial this number.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Copy Number'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                Navigator.of(context).pop();
                _showSnackBar('Phone number copied to clipboard', Colors.green);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToConflictTrip(int tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExceedTripDetailsScreen(
          userRole: widget.userRole,
          tripId: tripId,
          fromConflictNavigation: true,
        ),
      ),
    );
  }

  void _cleanupWebSocket() async {
    try {
      await _tripHandler.dispose();
      await _webSocketManager.disconnectFromNamespace('/trips');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up WebSocket: $e');
      }
    }
  }

  void _reconnectWebSocket() {
    setState(() {
      _isInitializing = true;
    });
    _initializeWebSocket();
  }

  // Helper methods to get token and userId
  Future<String?> _getToken() async {
    try {
      return await SecureStorageService().accessToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting token: $e');
      }
      return null;
    }
  }

  Future<String?> _getUserId() async {
    try {
      final user = StorageService.userData;
      return user?.id.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user ID: $e');
      }
      return null;
    }
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
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFF9C80E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.fromConflictNavigation
                    ? Icons.arrow_back
                    : Icons.arrow_back_ios_rounded,
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
                  widget.fromConflictNavigation
                      ? "Joined Trip #${_tripDetails?.id ?? widget.tripId}"
                      : widget.fromInstanceNavigation
                      ? "Instance Trip #${_tripDetails?.id ?? widget.tripId}"
                      : "Trip #${_tripDetails?.id ?? widget.tripId}",
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
          if (_tripDetails?.status != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_tripDetails!.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _tripDetails!.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(_tripDetails!.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMapSection() {
    final hasValidMarkers =
        _markers.isNotEmpty &&
        _markers.any(
          (marker) => marker.point.latitude != 0 && marker.point.longitude != 0,
        );

    final hasValidRoutes =
        _routeSegments.isNotEmpty &&
        _routeSegments.any((route) => route.points.isNotEmpty);

    if (!hasValidMarkers && !hasValidRoutes) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(
            top: BorderSide(color: Colors.grey[800]!),
            bottom: BorderSide(color: Colors.grey[800]!),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, color: Colors.grey[600], size: 40),
              SizedBox(height: 8),
              Text(
                'No route information available',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate center point
    LatLng getCenterPoint() {
      if (_mapBounds != null) {
        return _mapBounds!.center;
      }

      if (_markers.isNotEmpty) {
        final startMarker = _markers.firstWhere(
          (marker) => marker.point.latitude != 0 && marker.point.longitude != 0,
          orElse: () => _markers.first,
        );
        return startMarker.point;
      }

      return LatLng(7.8731, 80.7718); // Default Sri Lanka center
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: getCenterPoint(),
              initialZoom: _calculateOptimalZoom(),
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.vehiclereservation',
              ),
              if (_routeSegments.isNotEmpty)
                PolylineLayer(polylines: _routeSegments),
              if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
            ],
          ),
          // Legend for markers (keep this)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Start',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Stops',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'End',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictAlert() {
    if (_tripDetails?.conflicts.hasConflicts != true) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Connected Trips :',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_tripDetails?.conflicts.trips.isNotEmpty == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tripDetails!.conflicts.trips.map((trip) {
                    return ElevatedButton(
                      onPressed: () => _navigateToConflictTrip(trip.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.crop, size: 16),
                          SizedBox(width: 6),
                          Text('Trip #${trip.id}'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTripTypeSection() {
    if (_tripDetails?.tripType == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // Trip Type Badge
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTripTypeColor(_tripDetails!.tripType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getTripTypeColor(
                  _tripDetails!.tripType,
                ).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTripTypeColor(_tripDetails!.tripType),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getTripTypeIcon(_tripDetails!.tripType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTripTypeDisplayName(_tripDetails!.tripType),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (_tripDetails!.tripType == 'fixed_rate' &&
                          _tripDetails!.fixedRate != null)
                        Text(
                          'Fixed Rate: LKR ${_formatCurrency(_tripDetails!.fixedRate!)}',
                          style: TextStyle(
                            color: Color(0xFFF9C80E),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTripTypeColor(
                      _tripDetails!.tripType,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _tripDetails!.tripType.toUpperCase(),
                    style: TextStyle(
                      color: _getTripTypeColor(_tripDetails!.tripType),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reason Field
          if (_tripDetails?.reason != null && _tripDetails!.reason!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reason',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _tripDetails!.reason!,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Type Section - ADD THIS
          _buildTripTypeSection(),
          SizedBox(height: 8),

          Text(
            'Trip Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                Icons.edit_road,
                '${((double.tryParse(_tripDetails?.details.route.metrics.distance ?? '0') ?? 0) * 2).toStringAsFixed(1)} km',
                //'${((double.tryParse(_tripDetails?.details.route.metrics.estimatedDuration ?? '0') ?? 0) * 2).toStringAsFixed(0)} min',
                _formatDurationToHoursMinutes(
                  double.parse(
                        _tripDetails!.details.route.metrics.estimatedDuration,
                      ) *
                      2,
                ),
              ),
              SizedBox(width: 16),
              _buildMetricCard(
                Icons.calendar_month,
                _tripDetails != null ? '${_tripDetails!.startDate} ' : 'N/A',
                _tripDetails != null
                    ? DateFormat('hh:mm a').format(
                        DateFormat('HH:mm').parse(_tripDetails!.startTime),
                      )
                    : 'N/A',
              ),
            ],
          ),

          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                Icons.airline_seat_recline_normal,
                'Passengers',
                '${_tripDetails?.passengerCount ?? 0}',
              ),
              SizedBox(width: 16),
              _buildMetricCard(
                Icons.directions_car,
                _tripDetails?.vehicle.regNo != null &&
                        _tripDetails!.vehicle.regNo!.isNotEmpty
                    ? '${_tripDetails!.vehicle.regNo}'
                    : 'Vehicle',
                _tripDetails?.vehicle.model != null &&
                        _tripDetails!.vehicle.model!.isNotEmpty
                    ? '${_tripDetails!.vehicle.model}'
                    : 'Assigning...',
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildMetricsComparisonTable(),
          SizedBox(height: 16),
          _buildInfoRow(
            'Requested At',
            DateFormat(
              'yyyy-MM-dd hh:mm a',
            ).format(_tripDetails!.createdAt.toLocal()),
          ),
          _buildInfoRow('Request', ''),
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPassengerTypeColor('requester'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getPassengerTypeIcon('requester'),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _tripDetails!.requester.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPassengerTypeColor(
                                'requester',
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'REQUESTER',
                              style: TextStyle(
                                color: _getPassengerTypeColor('requester'),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Show department for requester
                      Text(
                        _tripDetails!.requester.department,
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tripDetails?.requester.phone ??
                                  'No contact number',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _makePhoneCall(_tripDetails!.requester.phone),
                            icon: Icon(
                              Icons.call,
                              color: Color(0xFFF9C80E),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: 'Call passenger',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_tripDetails?.purpose != null &&
              _tripDetails!.purpose!.isNotEmpty)
            _buildInfoRow('Purpose', _tripDetails!.purpose!),

          SizedBox(height: 4),
          _buildConflictAlert(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildVehicleSection() method:
  Widget _buildVehicleSection() {
    // Check if vehicle details are null or empty
    final hasVehicle =
        _tripDetails?.vehicle != null &&
        (_tripDetails!.vehicle.regNo != null &&
            _tripDetails!.vehicle.regNo!.isNotEmpty);

    final hasDrivers =
        _tripDetails?.details.drivers.hasDrivers == true &&
        (_tripDetails!.details.drivers.primary != null ||
            _tripDetails!.details.drivers.secondary != null);

    if (!hasVehicle && !hasDrivers) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supervisor under reviewing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vehicle will be assigned soon',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
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

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // Vehicle Information - Only show if has vehicle
          if (hasVehicle)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9C80E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tripDetails?.vehicle.model ?? 'N/A',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _tripDetails?.vehicle.regNo ?? 'N/A',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  /*
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildVehicleDetailChip(
                        Icons.airline_seat_recline_normal,
                        '${_tripDetails?.vehicle.seatingCapacity ?? 0} Seats',
                      ),
                      _buildVehicleDetailChip(
                        Icons.event_seat,
                        '${_tripDetails?.vehicle.seatingAvailability ?? 0} Available',
                      ),
                      if (_tripDetails
                                  ?.details
                                  .vehicleDetails
                                  .specifications
                                  .fuelType !=
                              null &&
                          _tripDetails!
                              .details
                              .vehicleDetails
                              .specifications
                              .fuelType!
                              .isNotEmpty)
                        _buildVehicleDetailChip(
                          Icons.local_gas_station,
                          _tripDetails!
                              .details
                              .vehicleDetails
                              .specifications
                              .fuelType!,
                        ),
                    ],
                  ),
                  */
                  SizedBox(height: 12),
                  if (_tripDetails
                          ?.details
                          .vehicleDetails
                          .status
                          .odometerLastReading !=
                      null)
                    Row(
                      children: [
                        Icon(Icons.speed, color: Colors.grey[400], size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Last Odometer: ${_tripDetails!.details.vehicleDetails.status.odometerLastReading} km',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Drivers Section - Only show if has drivers
          if (hasDrivers)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: hasVehicle ? 16 : 0),
                Text(
                  'Drivers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                if (_tripDetails?.details.drivers.primary != null)
                  _buildDriverCard(
                    _tripDetails!.details.drivers.primary!,
                    'Primary Driver',
                  ),
                if (_tripDetails?.details.drivers.secondary != null)
                  _buildDriverCard(
                    _tripDetails!.details.drivers.secondary!,
                    'Secondary Driver',
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Update the _buildApprovalSection() method:
  Widget _buildApprovalSection() {
    // Check if approval details are available
    final hasApprovers =
        (_tripDetails!.details.approval.approvers.hod?.id != -1 ||
        _tripDetails!.details.approval.approvers.secondary != null ||
        _tripDetails!.details.approval.approvers.safety != null);

    final hasApproval = _tripDetails?.details.approval.hasApproval == true;

    if (!hasApproval) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approval Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          //'Vehicle assignment pending',
                          _tripDetails?.schedule.isInstance == true
                              ? _tripDetails?.status.toLowerCase() == 'pending'
                                    ? 'Master trip under reviewing'
                                    : 'Master trip approved'
                              : 'Vehicle assignment pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          //'Approvers will be assigned shortly',
                          _tripDetails?.schedule.isInstance == true
                              ? _tripDetails?.status.toLowerCase() == 'pending'
                                    ? 'Master trip under reviewing and approvers will be assigned shortly'
                                    : 'Master trip approved and no need for instance approvals'
                              : 'Approvers will be assigned shortly',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
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
    } else if (hasApproval && !hasApprovers) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approval Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildApproverRow(
              'Auto approved',
              Approver(
                //name: 'Night trip (8PM-12AM) - No HOD approval needed',
                name: _tripDetails!.details.approval.approvers.hod?.comments ?? "Not a special",
                status: 'approved',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_tripDetails?.details.approval.approvers.hod != null) ...[
            _buildApproverRow(
              _tripDetails!.tripType == 'emergency'
                  ? 'Emergency Approval'
                  : 'HOD Approval',
              _tripDetails!.details.approval.approvers.hod!,
            ),
          ] else ...[
            _buildApproverRow(
              'Auto approved',
              Approver(
                //name: 'Night trip (8PM-12AM) - No HOD approval needed',
                name: _tripDetails!.details.approval.approvers.hod?.comments ?? "Not a special",
                status: 'approved',
              ),
            ),
          ],
          if (_tripDetails?.details.approval.approvers.secondary != null)
            _buildApproverRow(
              'Secondary Approval',
              _tripDetails!.details.approval.approvers.secondary!,
            ),
          // if (_tripDetails?.details.approval.approvers.safety != null)
          if (_tripDetails?.details.approval.requirements.requireSafetyApprover == true)
            _buildApproverRow(
              'Safety Approval',
              _tripDetails?.details.approval.approvers.safety,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsComparisonTable() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTableHeader('Estimated'),
                    _buildTableHeader('Actual'),
                  ],
                ),
              ),
            ],
          ),

          Divider(color: Colors.grey[700], height: 20),

          // Time Row
          _buildComparisonRow(
            label: 'Duration',
            estimatedValue: _formatDurationToHoursMinutes(
              double.parse(
                    _tripDetails!.details.route.metrics.estimatedDuration,
                  ) *
                  2,
            ),
            actualValue:
                _tripDetails?.status.toLowerCase() == 'completed' ||
                    _tripDetails?.status.toLowerCase() == 'exceed'
                ? _formatDurationToHoursMinutes(
                    double.parse(
                      _tripDetails!.details.route.metrics.actualDuration
                          .toString(),
                    ),
                  )
                : '--',
          ),

          SizedBox(height: 12),

          // Distance Row
          _buildComparisonRow(
            label: 'Distance (km)',
            estimatedValue:
                '${(double.parse(_tripDetails!.details.route.metrics.distance) * 2).toStringAsFixed(1)}',
            actualValue:
                _tripDetails?.status.toLowerCase() == 'completed' ||
                    _tripDetails?.status.toLowerCase() == 'exceed'
                ? '${_tripDetails!.details.route.metrics.actualDistance}'
                : '--',
          ),

          /*
          SizedBox(height: 12),

          // Cost Row
          _buildComparisonRow(
            label: 'Cost (LKR)',
            estimatedValue: _formatCurrency(
              double.parse(_tripDetails!.details.route.metrics.distance) *
                  2 *
                  double.parse(_tripDetails?.vehicle.costPerKm ?? '0'),
            ),
            actualValue: _tripDetails?.status.toLowerCase() == 'completed'
            || _tripDetails?.status.toLowerCase() == 'exceed'
                ? _formatCurrency(_tripDetails!.cost ?? 0)
                : '--',
          ),
          */
        ],
      ),
    );
  }

  String _formatDurationToHoursMinutes(double minutes) {
    int totalMinutes = minutes.round();
    int hours = totalMinutes ~/ 60;
    int remainingMinutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}min';
    } else {
      return '${remainingMinutes}min';
    }
  }

  String _formatCurrency(num value, {bool includeDecimals = true}) {
    final pattern = includeDecimals ? '#,##0.00' : '#,##0';
    final formatter = NumberFormat(pattern, 'en_US');
    return formatter.format(value);
  }

  Widget _buildTableHeader(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFF9C80E), // Yellow color
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String label,
    required String estimatedValue,
    required String actualValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label row
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Values row
        Container(
          decoration: BoxDecoration(
            //border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Estimated value
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        estimatedValue,
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Separator with decoration
              Container(width: 2),

              // Actual value
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _tripDetails?.status.toLowerCase() == 'completed'
                        ? Colors.greenAccent.withOpacity(0.2)
                        : Colors.grey[800]!.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actualValue,
                        style: TextStyle(
                          color:
                              _tripDetails?.status.toLowerCase() == 'completed'
                              ? Colors.greenAccent
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Update the _buildVehicleDetailChip method to handle null values:
  Widget _buildVehicleDetailChip(IconData icon, String text) {
    // If text is empty or "0", show placeholder
    final displayText = text.isNotEmpty && text != "0" ? text : 'N/A';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFFF9C80E), size: 14),
          SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Update the driver card to handle null values:
  Widget _buildDriverCard(Driver driver, String role) {
    // Check if driver has valid data
    final hasValidName = driver.name != null && driver.name.isNotEmpty;
    final hasValidPhone = driver.phone != null && driver.phone.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: role.contains('Primary') ? Colors.blue : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        hasValidName ? driver.name : 'Driver Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role.contains('Primary')
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: role.contains('Primary')
                              ? Colors.blue
                              : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.grey[400], size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasValidPhone ? driver.phone : 'Phone not available',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasValidPhone)
                      IconButton(
                        onPressed: () => _makePhoneCall(driver.phone),
                        icon: Icon(
                          Icons.call,
                          color: Color(0xFFF9C80E),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Call driver',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildVehicleSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          // Vehicle Information
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFF9C80E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.directions_car, color: Colors.black, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tripDetails?.vehicle.model ?? 'N/A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _tripDetails?.vehicle.regNo ?? 'N/A',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildVehicleDetailChip(
                      Icons.airline_seat_recline_normal,
                      '${_tripDetails?.vehicle.seatingCapacity ?? 0} Seats',
                    ),
                    _buildVehicleDetailChip(
                      Icons.event_seat,
                      '${_tripDetails?.vehicle.seatingAvailability ?? 0} Available',
                    ),
                    _buildVehicleDetailChip(
                      Icons.local_gas_station,
                      _tripDetails?.details.vehicleDetails.specifications.fuelType ?? 'N/A',
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (_tripDetails?.details.vehicleDetails.status.odometerLastReading != null)
                  Row(
                    children: [
                      Icon(Icons.speed, color: Colors.grey[400], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Last Odometer: ${_tripDetails!.details.vehicleDetails.status.odometerLastReading} km',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Drivers Section
          if (_tripDetails?.details.drivers.hasDrivers == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  'Drivers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                if (_tripDetails?.details.drivers.primary != null)
                  _buildDriverCard(
                    _tripDetails!.details.drivers.primary!,
                    'Primary Driver',
                  ),
                if (_tripDetails?.details.drivers.secondary != null)
                  _buildDriverCard(
                    _tripDetails!.details.drivers.secondary!,
                    'Secondary Driver',
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFFF9C80E), size: 14),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Driver driver, String role) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: role.contains('Primary') ? Colors.blue : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role.contains('Primary') 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: role.contains('Primary') ? Colors.blue : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.grey[400], size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        driver.phone,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _makePhoneCall(driver.phone),
                      icon: Icon(Icons.call, color: Color(0xFFF9C80E), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      tooltip: 'Call driver',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSection() {
    if (_tripDetails?.details.approval.hasApproval != true) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_tripDetails?.details.approval.approvers.hod != null)
            _buildApproverRow(
              'HOD Approval',
              _tripDetails!.details.approval.approvers.hod!,
            ),
          if (_tripDetails?.details.approval.approvers.secondary != null)
            _buildApproverRow(
              'Secondary Approval',
              _tripDetails!.details.approval.approvers.secondary!,
            ),
          // if (_tripDetails?.details.approval.approvers.safety != null)
          if (_tripDetails?.details.approval.requirements.requireSafetyApprover == true)
            _buildApproverRow(
              'Safety Approval',
              _tripDetails?.details.approval.approvers.safety,
            ),
        ],
      ),
    );
  }
*/
  Widget _buildLocationsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildLocationRow(
            Icons.location_on,
            Colors.green,
            'Start',
            _tripDetails?.location.startAddress ?? 'N/A',
          ),
          SizedBox(height: 8),
          if (_tripDetails?.details.route.stops.intermediate.isNotEmpty == true)
            Column(
              children: [
                ..._tripDetails!.details.route.stops.intermediate
                    .map(
                      (stop) => _buildLocationRow(
                        Icons.location_on,
                        Colors.orange,
                        'Stop ${stop.order}',
                        stop.address,
                      ),
                    )
                    .toList(),
                SizedBox(height: 8),
              ],
            ),
          _buildLocationRow(
            Icons.location_on,
            Colors.red,
            'End',
            _tripDetails?.location.endAddress ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    Color color,
    String label,
    String address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String value) {
    return Expanded(
      //width: 120,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFFF9C80E), size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersSection() {
    if (_tripDetails?.details.passengers.list.isEmpty == true) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passengers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ..._tripDetails!.details.passengers.list
              .map(
                (passenger) => Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getPassengerTypeColor(passenger.type),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getPassengerTypeIcon(passenger.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    passenger.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPassengerTypeColor(
                                      passenger.type,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    passenger.type.toUpperCase(),
                                    style: TextStyle(
                                      color: _getPassengerTypeColor(
                                        passenger.type,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            // Show department for requester
                            if (passenger.department != null)
                              Text(
                                _tripDetails!.requester.department,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                ),
                              ),
                            SizedBox(height: 4),
                            if (passenger.contactNo != null &&
                                passenger.contactNo!.isNotEmpty)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      passenger.contactNo!,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _makePhoneCall(passenger.contactNo!),
                                    icon: Icon(
                                      Icons.call,
                                      color: Color(0xFFF9C80E),
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    tooltip: 'Call passenger',
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Color _getPassengerTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'requester':
        return Colors.blue;
      case 'group':
        return Colors.green;
      case 'guest':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPassengerTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'requester':
        return Icons.person;
      case 'group':
        return Icons.group;
      case 'guest':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  Widget _buildApproverRow(String label, Approver? approver) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getApprovalStatusColor(approver?.status ?? 'pending'),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getApprovalStatusIcon(approver?.status ?? 'pending'),
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                // Show department 
                if (approver?.department != null)
                  Text(
                    approver?.department ?? '',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                SizedBox(height: 4),
                Text(
                  approver?.name ?? 'Pending Assignee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (approver?.comments != null && approver!.comments!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Comment: ${approver.comments}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getApprovalStatusColor(approver?.status ?? 'pending').withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              approver?.status.toUpperCase() ?? 'PENDING',
              style: TextStyle(
                color: _getApprovalStatusColor(approver?.status ?? 'pending'),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getApprovalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getApprovalStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _tripDetails == null
          ? _buildNoDataState()
          : _buildContent(),
    );
  }

  // Add this method in the _TripDetailsScreenState class
  Widget _buildCancelButton() {
    // Check if the current user is the trip requester
    final isRequester =
        StorageService.userData?.id == _tripDetails?.requester.id;

    final isPermissionUser =
        widget.userRole == UserRole.sysadmin ||
        widget.userRole == UserRole.supervisor;

    // Get approval status
    final approval = _tripDetails?.details.approval;
    final hasApproval = approval?.hasApproval == true;

    // Check approval statuses
    final hodStatus = approval?.approvers.hod?.status ?? '';
    final secondaryStatus = approval?.approvers.secondary?.status ?? '';
    final safetyStatus = approval?.approvers.safety?.status ?? '';

    // Check if any approver has approved
    final hasAnyApproval =
        hodStatus.toLowerCase() == 'approved' ||
        secondaryStatus.toLowerCase() == 'approved' ||
        safetyStatus.toLowerCase() == 'approved';

    // Check if all are pending (no approvals yet)
    final allPending =
        !hasAnyApproval &&
        (hodStatus.toLowerCase() == 'pending' || hodStatus == '') &&
        (secondaryStatus.toLowerCase() == 'pending' || secondaryStatus == '') &&
        (safetyStatus.toLowerCase() == 'pending' || safetyStatus == '');

    // Check if trip can be cancelled based on status
    final canCancelTrip =
        isPermissionUser &&
        (_tripDetails?.status == 'pending' ||
            _tripDetails?.status == 'draft') &&
        allPending;

    if (!isPermissionUser || !canCancelTrip) {
      return SizedBox.shrink(); // Only show to permission users
    }

    if (hasAnyApproval) {
      // Trip partially approved - show disabled button with message
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cannot Cancel Trip',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This trip has been partially approved by supervisors. '
              'Only trips with zero approval can be cancelled.',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.grey[400],
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Trip Partially Approved',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (!allPending) {
      // Some other approval state (rejected, etc.)
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.grey[400],
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, size: 20),
              SizedBox(width: 8),
              Text(
                'Trip Status: ${_tripDetails?.status?.toUpperCase() ?? 'N/A'}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    } else if (canCancelTrip) {
      // Trip can be cancelled - show active cancel button
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: ElevatedButton(
          onPressed: () => _showCancelConfirmationDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, size: 20),
              SizedBox(width: 8),
              Text('Cancel This Trip', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    } else {
      // Trip cannot be cancelled for other reasons
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.grey[400],
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, size: 20),
              SizedBox(width: 8),
              Text('Trip Cannot Be Cancelled', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
  }

  bool _isTripInPast() {
    if (_tripDetails == null) return false;

    try {
      // Parse the trip date and time
      final tripDateStr = _tripDetails!.startDate; // Format: YYYY-MM-DD
      final tripTimeStr = _tripDetails!.startTime; // Format: HH:mm

      if (tripDateStr.isEmpty || tripTimeStr.isEmpty) return false;

      // Parse date
      final tripDate = DateTime.parse(tripDateStr);

      // Parse time
      final timeParts = tripTimeStr.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Combine date and time
        final tripDateTime = DateTime(
          tripDate.year,
          tripDate.month,
          tripDate.day,
          hour,
          minute,
        );

        // Compare with current time
        final now = DateTime.now();
        return tripDateTime.isBefore(now);
      }

      // If time parsing fails, just compare dates
      return tripDate.isBefore(DateTime.now());
    } catch (e) {
      print('Error checking if trip is in past: $e');
      return false;
    }
  }

  /*
  Widget _buildActionButtons() {
    final isPermissionUser =
        widget.userRole == UserRole.sysadmin ||
        widget.userRole == UserRole.supervisor;

    final isRequester =
        StorageService.userData?.id == _tripDetails?.requester.id;
    final isPassenger =
        _tripDetails?.details.passengers.list.any(
          (p) => p.id.toString() == StorageService.userData?.id.toString(),
        ) ??
        false;

     // Check if trip is in the past
    final bool isPastTrip = _isTripInPast();       

    // Get actual available seats from trip details
    final availableSeats = _tripDetails?.availableSeatCount ?? 0;
    //final availableSeats = 0;
    final hasAvailableSeats = availableSeats > 0;

    // Trip status check
    final isTripActive =
        _tripDetails?.status.toLowerCase() == 'pending' ||
        _tripDetails?.status.toLowerCase() == 'approved';

    // Check if user is already in trip (as requester or passenger)
    final isUserInTrip = isPassenger;

    // Cancel button logic
    final approval = _tripDetails?.details.approval;
    final hodStatus = approval?.approvers.hod?.status ?? '';
    final secondaryStatus = approval?.approvers.secondary?.status ?? '';
    final safetyStatus = approval?.approvers.safety?.status ?? '';

    final hasAnyApproval =
        hodStatus.toLowerCase() == 'approved' ||
        secondaryStatus.toLowerCase() == 'approved' ||
        safetyStatus.toLowerCase() == 'approved';

    final allPending =
        !hasAnyApproval &&
        (hodStatus.toLowerCase() == 'pending' || hodStatus == '') &&
        (secondaryStatus.toLowerCase() == 'pending' || secondaryStatus == '') &&
        (safetyStatus.toLowerCase() == 'pending' || safetyStatus == '');

    final canCancelTrip =
        isPermissionUser &&
        (_tripDetails?.status == 'pending' ||
            _tripDetails?.status == 'draft') &&
        allPending;

    // Cancel button properties
    bool isCancelEnabled = canCancelTrip;
    Color cancelButtonColor = isCancelEnabled ? Colors.red : Colors.grey[700]!;
    String cancelButtonText = isCancelEnabled ? 'Cancel Trip' : "Can't Cancel";
    VoidCallback? cancelOnPressed;
    String cancelError = '';

    if (isCancelEnabled) {
      cancelOnPressed = _showCancelConfirmationDialog;
    } else {
      if (!isPermissionUser) {
        cancelError = 'Only supervisors or sysadmin can cancel trips';
      } else if (_tripDetails?.status != 'pending' &&
          _tripDetails?.status != 'draft') {
        cancelError = 'Only pending or draft trips can be cancelled';
      } else if (hasAnyApproval) {
        cancelError = 'Cannot cancel: Trip has been partially approved';
      } else {
        cancelError = 'Trip cannot be cancelled at this time';
      }
      cancelOnPressed = cancelError.isNotEmpty
          ? () => _showErrorDialog('Cannot Cancel Trip', cancelError)
          : null;
    }

    // Join/Add Passenger button properties
    bool isJoinEnabled = false;
    String joinButtonText = '';
    Color joinButtonColor = Colors.grey[700]!;
    VoidCallback? joinOnPressed;
    String joinError = '';

    if (isPermissionUser) {
      isJoinEnabled = isTripActive && hasAvailableSeats;
      joinButtonText = isJoinEnabled ? 'Add Passenger' : "Can't Add";
      joinButtonColor = isJoinEnabled ? Colors.green : Colors.grey[700]!;

      if (isJoinEnabled) {
          joinOnPressed = _showJoinTripConfirmation;
      } else {
        if (!isTripActive) {
          joinError = 'Cannot add: Trip is not active(Draft trip)';
        } else if (isPastTrip) {
          joinError = 'Cannot add: Trip is in the past';
        } else if (!hasAvailableSeats) {
            joinError = 'Under development: Cannot join - seat availability check not implemented yet';
          //joinError = 'Cannot add: No available seats (0 seats left)';
        }
        joinOnPressed = joinError.isNotEmpty
            ? () => _showErrorDialog('Cannot Add Trip', joinError)
            : null;
      }

    } else {
      // For regular users: "Join Trip" button
      if (isUserInTrip) {
        joinButtonText = 'Already Joined';
        isJoinEnabled = false;
        joinButtonColor = Colors.grey[700]!;
        joinError = 'You are already part of this trip';
        joinOnPressed = joinError.isNotEmpty
            ? () => _showErrorDialog('Cannot Join Trip', joinError)
            : null;
      } else {
        // Regular users can only join if trip is active AND seats are available
        isJoinEnabled = isTripActive && hasAvailableSeats;
        joinButtonText = isJoinEnabled ? 'Join Trip' : "Can't Join";
        joinButtonColor = isJoinEnabled ? Color(0xFFF9C80E) : Colors.grey[700]!;

        if (isJoinEnabled) {
          joinOnPressed = _showJoinTripConfirmation;
        } else {
          if (!isTripActive) {
            joinError = 'Cannot join: Trip is not active';
          } else if (isPastTrip) {
            joinError = 'Cannot join: Trip is in the past';
          } else if (!hasAvailableSeats) {
            joinError = 'Under development: Cannot join - seat availability check not implemented yet';
            //joinError = 'Cannot join: No available seats (0 seats left)';
          }
          joinOnPressed = joinError.isNotEmpty
              ? () => _showErrorDialog('Cannot Join Trip', joinError)
              : null;
        }
      }
    }

    // Ensure joinButtonText is never empty
    if (joinButtonText.isEmpty) {
      joinButtonText = isPermissionUser 
        ? isJoinEnabled 
          ? 'Add Passenger' 
          : "Can't Add" 
        : isJoinEnabled
          ? 'Join Trip'
          : "Can't Join" ;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          // Cancel Button
          if (isPermissionUser) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: cancelOnPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cancelButtonColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isCancelEnabled ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 20),
                    SizedBox(width: 8),
                    Text(
                      cancelButtonText, 
                      style: TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 12),
          ],
          // Join/Add Passenger Button - Always show
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton(
                  onPressed: joinOnPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: joinButtonColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isJoinEnabled ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPermissionUser
                            ? Icons.person_add
                            : Icons.add_box,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          joinButtonText,
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Show seat count indicator for non-permission users
                if (isTripActive && (!isPermissionUser || !isUserInTrip ))
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasAvailableSeats ? Colors.blueGrey : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        //border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        '$availableSeats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
    );
  }
  */
  Widget _buildActionButtons() {
    final isPermissionUser =
        widget.userRole == UserRole.sysadmin ||
        widget.userRole == UserRole.supervisor;

    // Only show action buttons for permission users
    if (!isPermissionUser || _tripDetails?.status.toLowerCase() != 'exceed') {
      return SizedBox.shrink(); // Return empty widget for non-permission users
    }

    // Permission user Accept button logic
    bool isAcceptEnabled = false;
    String acceptButtonText = '';
    Color acceptButtonColor = Colors.grey[700]!;
    VoidCallback? acceptOnPressed;
    String acceptError = '';

    // Permission users can accept trips if:
    // 1. Trip is pending
    // 2. Trip is not in the past
    isAcceptEnabled = true;
    acceptButtonText = 'Accept Trip';
    acceptButtonColor = Colors.green;
    acceptOnPressed = _showAcceptTripConfirmation;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          // Accept Button
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton(
                  onPressed: acceptOnPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: acceptButtonColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isAcceptEnabled ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          acceptButtonText,
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.check_circle, size: 20),
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

  void _showAcceptTripConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Accept Trip'),
          content: Text('Are you sure you want to accept this trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptTrip();
              },
              child: Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _acceptTrip() async {
    try {
      final response = await ApiService.acceptExceedTrip(widget.tripId);

      if (response['success'] == true) {
        MessageOverlay.showSuccess(
          context: context,
          message: 'Exceed trip accepted successfully!',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: const Duration(seconds: 2),
          onComplete: () {
            Navigator.pop(context, true);
          },
        );
      } else {
        throw Exception(response['message'] ?? 'Acceptance failed');
      }
    } catch (e) {
      setState(() {
        MessageOverlay.showError(
          context: context,
          message: 'Error accepting trip: ${e.toString()}',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          showOkButton: true,
        );
      });
    }
  }

  // Add this helper method for error dialogs
  Future<void> _showErrorDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(215, 83, 83, 83),
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Color(0xFFF9C80E))),
          ),
        ],
      ),
    );
  }

  // Add these helper methods for join trip functionality
  Future<void> _showJoinTripConfirmation() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(215, 83, 83, 83),
        title: Text('Confirm Join Trip', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to join this trip?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 8),
            Text(
              'Trip ID: #${_tripDetails?.id}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 8),
            Text(
              'Available Seats: ${_tripDetails?.availableSeatCount}',
              style: TextStyle(color: Colors.green),
            ),
            if (_tripDetails?.tripType == 'fixed_rate' &&
                _tripDetails?.fixedRate != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Fixed Rate: LKR ${_formatCurrency(_tripDetails!.fixedRate!)}',
                  style: TextStyle(color: Color(0xFFF9C80E)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF9C80E)),
            child: Text('Yes, Join', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _joinTrip();
    }
  }

  Future<void> _showAddPassengerDialog() async {
    if (_tripDetails == null) return;

    final availableSeats = _tripDetails!.availableSeatCount ?? 0;

    // Get list of users already in the trip to exclude them
    final existingPassengerIds = _tripDetails!.details.passengers.list
        .map((p) => {'id': p.id.toString(), 'displayName': p.name})
        .toList();

    if (availableSeats <= 0) {
      _showErrorDialog(
        'No Seats Available',
        'This trip has no available seats left.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => UserSearchDialog(
        title: 'Add Passengers to Trip #${_tripDetails!.id}',
        onUsersSelected: (selectedUsers) =>
            _addMultiplePassengersToTrip(selectedUsers),
        maxSelections: availableSeats,
        currentSelections: _tripDetails!.details.passengers.list.length,
        excludedUserIds: existingPassengerIds,
      ),
    );
  }

  Future<void> _addMultiplePassengersToTrip(
    List<Map<String, dynamic>> users,
  ) async {
    if (users.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Extract user IDs
      final userIds = users.map((user) => user['id']).toList();

      // Call API to add multiple passengers to trip
      final response = await ApiService.addMultiplePassengersToTrip(
        widget.tripId,
        userIds,
      );

      if (response['success'] == true) {
        final addedCount = response['data']?['addedCount'] ?? users.length;

        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added $addedCount passenger${addedCount != 1 ? 's' : ''} to the trip',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        */
        MessageOverlay.showSuccess(
          context: context,
          message:
              'Successfully added $addedCount passenger${addedCount != 1 ? 's' : ''} to the trip',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: const Duration(seconds: 2),
          onComplete: () {},
        );

        // Reload trip details to update passenger list and available seats
        await _loadTripDetails();
      } else {
        throw Exception(response['message'] ?? 'Failed to add passengers');
      }
    } catch (e) {
      /*
      print('Error adding passengers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding passengers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      */
      MessageOverlay.showError(
        context: context,
        message: 'Error adding passengers: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTrip() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Call API to join trip
      final response = await ApiService.joinTrip(widget.tripId);

      if (response['success'] == true) {
        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined the trip'),
            backgroundColor: Colors.green,
          ),
        );
        */
        MessageOverlay.showSuccess(
          context: context,
          message: 'Successfully joined the trip',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: const Duration(seconds: 2),
          onComplete: () {},
        );

        // Reload trip details to update available seats and passenger list
        await _loadTripDetails();
      } else {
        throw Exception(response['message'] ?? 'Failed to join trip');
      }
    } catch (e) {
      /*
      print('Error joining trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      */
      MessageOverlay.showError(
        context: context,
        message: 'Error joining trip: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this method for the confirmation dialog
  Future<void> _showCancelConfirmationDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(215, 83, 83, 83),
        title: Text(
          'Confirm Cancellation',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this trip?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 8),
            Text(
              'Trip ID: #${_tripDetails?.id}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 8),
            Text(
              'Note: This action cannot be undone.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Yes, Cancel Trip',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _cancelTrip();
    }
  }

  // Add this method to handle trip cancellation
  Future<void> _cancelTrip() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.cancelTrip(widget.tripId);

      if (response['success'] == true) {
        /*
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        */
        MessageOverlay.showSuccess(
          context: context,
          message: 'Trip cancelled successfully',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: const Duration(seconds: 2),
          onComplete: () {},
        );

        // Reload trip details to update status
        await _loadTripDetails();
      } else {
        throw Exception(response['message'] ?? 'Failed to cancel trip');
      }
    } catch (e) {
      /*
      print('Error cancelling trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      */
      MessageOverlay.showError(
        context: context,
        message: 'Error cancelling trip: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the _buildContent() method to include the cancel button:
  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMapSection(),
                      _buildTripInfoSection(),
                      _buildScheduleSection(),
                      _buildVehicleSection(),
                      _buildLocationsSection(),
                      _buildPassengersSection(),
                      _buildApprovalSection(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              //_buildCancelButton(), // Add cancel button at the bottom
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    // Only show if it's a scheduled trip
    if (_tripDetails?.schedule.isScheduled == false &&
        _tripDetails?.schedule.isInstance == false) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Schedule Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tripDetails!.schedule.isInstance ? 'INSTANCE' : 'MASTER',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Master Trip Link (if instance)
          if (_tripDetails!.schedule.isInstance &&
              _tripDetails!.schedule.masterTripId != null)
            Column(
              children: [
                _buildScheduleInfoRow(
                  Icons.link,
                  'Master Trip',
                  'Trip ${_tripDetails!.schedule.masterTripId}',
                  () => _navigateToTrip(
                    _tripDetails!.schedule.masterTripId!,
                    false,
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),

          // Instance date (if instance)
          if (_tripDetails!.schedule.isInstance &&
              _tripDetails!.schedule.instanceDate != null)
            Column(
              children: [
                _buildScheduleInfoRow(
                  Icons.calendar_today,
                  'Instance Date',
                  _tripDetails!.schedule.instanceDate!,
                  null,
                ),
                SizedBox(height: 8),
              ],
            ),

          // For MASTER trips: Put Repetition and Valid Till in one row
          if (!_tripDetails!.schedule.isInstance)
            Row(
              children: [
                Expanded(
                  child: _buildScheduleInfoRow(
                    Icons.repeat,
                    'Repetition',
                    _tripDetails!.repetition,
                    null,
                  ),
                ),
                SizedBox(width: 12),
                if (_tripDetails!.schedule.validTillDate != null)
                  Expanded(
                    child: _buildScheduleInfoRow(
                      Icons.calendar_today,
                      'Valid Till',
                      _tripDetails!.schedule.validTillDate!,
                      null,
                    ),
                  ),
              ],
            ),

          SizedBox(height: 8),

          // For MASTER trips: Put Include Weekends and Repeat After in one row
          if (!_tripDetails!.schedule.isInstance)
            Row(
              children: [
                Expanded(
                  child: _buildScheduleInfoRow(
                    Icons.weekend,
                    'Include Weekends',
                    _tripDetails!.schedule.includeWeekends ? 'Yes' : 'No',
                    null,
                  ),
                ),
                SizedBox(width: 12),
                if (_tripDetails!.schedule.repeatAfterDays != null)
                  Expanded(
                    child: _buildScheduleInfoRow(
                      Icons.timer,
                      'Repeat After',
                      '${_tripDetails!.schedule.repeatAfterDays} days',
                      null,
                    ),
                  ),
              ],
            ),

          SizedBox(height: 8),

          // Instance count and list (for master trips)
          if (!_tripDetails!.schedule.isInstance &&
              _tripDetails!.schedule.instanceCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScheduleInfoRow(
                  Icons.list,
                  'Instances',
                  '${_tripDetails!.schedule.instanceCount} instances',
                  null,
                ),
                SizedBox(height: 8),

                // Show instance IDs as clickable buttons
                if (_tripDetails!.schedule.instanceIds != null &&
                    _tripDetails!.schedule.instanceIds!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instance IDs:',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: _tripDetails!.schedule.instanceIds!.map((
                          instanceId,
                        ) {
                          return ElevatedButton(
                            onPressed: () =>
                                _navigateToTrip(instanceId.id, true),
                            //onPressed: () => print('tap trip id'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              foregroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trip_origin, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Trip ${_formatDateToMonthDay(instanceId.startDate)}',
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),

          SizedBox(height: 8),

          // Instance list (if viewing an instance, show other instances)
          if (_tripDetails!.schedule.isInstance &&
              _tripDetails!.schedule.instanceIds != null &&
              _tripDetails!.schedule.instanceIds!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Instances:',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tripDetails!.schedule.instanceIds!
                      .where((id) => id.id != _tripDetails!.id)
                      .map((instanceId) {
                        return ElevatedButton(
                          onPressed: () => _navigateToTrip(instanceId.id, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trip_origin, size: 14),
                              SizedBox(width: 4),
                              Text('Trip #$instanceId'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDateToMonthDay(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildScheduleInfoRow(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.blue.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                  SizedBox(height: 0),
                  Text(
                    value,
                    style: TextStyle(
                      color: onTap != null ? Colors.blue : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 14),
          ],
        ),
      ),
    );
  }

  // Add this navigation method
  void _navigateToTrip(int tripId, bool isInstance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExceedTripDetailsScreen(
          userRole: widget.userRole,
          tripId: tripId,
          fromInstanceNavigation: isInstance,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isInitializing)
                  CircularProgressIndicator(color: Color(0xFFF9C80E)),
                SizedBox(height: 16),
                Text(
                  _isInitializing
                      ? 'Connecting to real-time updates...'
                      : 'Loading trip details...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTripDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF9C80E),
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 50),
                SizedBox(height: 16),
                Text(
                  'No trip details found',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Trip ID: ${widget.tripId}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
