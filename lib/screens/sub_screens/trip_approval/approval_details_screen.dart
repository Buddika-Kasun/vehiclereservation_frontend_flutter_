import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiclereservation_frontend_flutter_/models/approval_model.dart';
import 'package:vehiclereservation_frontend_flutter_/models/trip_details_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:intl/intl.dart';

class ApprovalDetailsScreen extends StatefulWidget {
  final int tripId;
  final bool fromConflictNavigation;
  final bool fromInstanceNavigation;
  final ApprovalTrip? tripData; // Add this parameter

  const ApprovalDetailsScreen({
    Key? key,
    required this.tripId,
    this.fromConflictNavigation = false,
    this.fromInstanceNavigation = false,
    this.tripData, // Add optional tripData parameter
  }) : super(key: key);

  @override
  _ApprovalDetailsScreenState createState() => _ApprovalDetailsScreenState();
}

class _ApprovalDetailsScreenState extends State<ApprovalDetailsScreen> {
  TripDetails? _tripDetails;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNotificationShowing = false;

  // Map related variables
  List<Marker> _markers = [];
  List<Polyline> _routeSegments = [];
  LatLngBounds? _mapBounds;

  // Approval action variables
  bool _isApproving = false;
  bool _isRejecting = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _rejectionController = TextEditingController();
  bool _isProcessing = false; // Add this missing variable
  String _approverComment = ''; // Add this missing variable

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
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
                    color: Color(segment.color ?? 0xFF0000FF), // Default blue
                    strokeWidth: (segment.strokeWidth ?? 4.0).toDouble(),
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
      width: 70,
      height: 80,
      child: GestureDetector(
        onTap: () {
          if (_isNotificationShowing) return;

          setState(() {
            _isNotificationShowing = true;
          });

          final screenHeight = MediaQuery.of(context).size.height;

          ScaffoldMessenger.of(context)
              .showSnackBar(
                SnackBar(
                  content: Container(
                    height: 60,
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
                    bottom: screenHeight - 170,
                    left: 2,
                    right: 2,
                  ),
                ),
              )
              .closed
              .then((reason) {
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
    final parts = fullAddress.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    return fullAddress;
  }

  double _calculateOptimalZoom() {
    if (_markers.isEmpty && _routeSegments.isEmpty) return 12.0;

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
    double latSpanMeters = latSpan * 111000;
    double lngSpanMeters = lngSpan * 111000 * cos(minLat * 3.14159265 / 180);

    // Use the larger span
    double maxSpanMeters = max(latSpanMeters, lngSpanMeters);

    // Calculate zoom level based on span
    if (maxSpanMeters < 500) return 16.0;
    if (maxSpanMeters < 1000) return 15.0;
    if (maxSpanMeters < 2000) return 14.0;
    if (maxSpanMeters < 5000) return 13.0;
    if (maxSpanMeters < 10000) return 12.0;
    if (maxSpanMeters < 20000) return 11.0;
    if (maxSpanMeters < 50000) return 10.0;
    if (maxSpanMeters < 100000) return 9.0;
    return 8.0;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot make call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Approve Trip', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to approve this trip?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add optional comments...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color.fromRGBO(97, 97, 97, 1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFF9C80E)),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              onChanged: (value) {
                _approverComment = value; // Update the comment
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: _isApproving
                ? null
                : () {
                    Navigator.pop(context);
                    _approveTrip();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isApproving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Reject Trip', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _rejectionController,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color.fromRGBO(97, 97, 97, 1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: TextStyle(color: Colors.white),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: _isRejecting
                ? null
                : () {
                    Navigator.pop(context);
                    _rejectTrip();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isRejecting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveTrip() async {
    // Show confirmation dialog for scheduled trips
    bool shouldApprove = true;

    // Check if this is a scheduled trip using widget.tripData
    if (widget.tripData?.isScheduled == true) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.repeat, color: Colors.blue),
              SizedBox(width: 4),
              Expanded(
                // Wrap Text with Expanded
                child: Text(
                  'Approve Scheduled Trip',
                  overflow: TextOverflow.ellipsis, // Add overflow handling
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is a scheduled trip with ${widget.tripData?.instanceCount ?? 0} instances.',
              ),
              SizedBox(height: 8),
              Text(
                'Do you want to approve ALL instances at once?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (widget.tripData?.instanceCount != null &&
                  widget.tripData!.instanceCount! > 0)
                Text(
                  'This will approve ${widget.tripData!.instanceCount} trip instances.',
                  style: TextStyle(color: Colors.blue),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Approve All'),
            ),
          ],
        ),
      );

      shouldApprove = result ?? false;
    }

    if (!shouldApprove) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> response;

      // Use different API for scheduled trips
      if (widget.tripData?.isScheduled == true &&
          widget.tripData?.isInstance == false) {
        // Use the new approveScheduledTrip API
        response = await ApiService.approveScheduledTrip(
          widget.tripId,
          _commentController.text,
        );
      } else {
        // Regular approval for one-time trips or instances
        response = await ApiService.approveTrip(
          widget.tripId,
          _commentController.text,
        );
      }

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.tripData?.isScheduled == true
                  ? 'Scheduled trip approved successfully!'
                  : 'Trip approved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Return success to parent screen
        Navigator.pop(context, true);
      } else {
        throw Exception(response['message'] ?? 'Approval failed');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error approving trip: ${e.toString()}';
        _isProcessing = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectTrip() async {
    try {
      setState(() {
        _isRejecting = true;
      });

      final res = await ApiService.rejectTrip(
        widget.tripId,
        _rejectionController.text,
      );

      await Future.delayed(Duration(seconds: 1));

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trip rejected'), backgroundColor: Colors.red),
        );
      }

      // Wait a bit for user to see the message
      await Future.delayed(Duration(seconds: 1));

      // Return to previous screen with refresh flag
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRejecting = false;
        });
      }
    }
  }

  void _navigateToConflictTrip(int tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ApprovalDetailsScreen(tripId: tripId, fromConflictNavigation: true),
      ),
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
            child: Text(
              widget.fromConflictNavigation
                  ? "Joined Trip #${_tripDetails?.id ?? widget.tripId}"
                  : widget.fromInstanceNavigation
                    ? "Instance Trip #${_tripDetails?.id ?? widget.tripId}"
                    : "Trip #${_tripDetails?.id ?? widget.tripId}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
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
          // Legend for markers
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
                '${_tripDetails?.details.route.metrics.distance ?? 0} km',
                '${_tripDetails?.details.route.metrics.estimatedDuration ?? 0} min',
              ),
              _buildMetricCard(
                Icons.calendar_month,
                _tripDetails?.startDate ?? 'N/A',
                _tripDetails != null && _tripDetails!.startTime.isNotEmpty
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
              _buildMetricCard(
                Icons.directions_car,
                _tripDetails?.vehicle.regNo ?? 'N/A',
                _tripDetails?.vehicle.model ?? 'N/A',
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            'Requested At',
            DateFormat(
              'yyyy-MM-dd hh:mm a',
            ).format(_tripDetails?.createdAt?.toLocal() ?? DateTime.now()),
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
                              _tripDetails?.requester.name ?? 'Unknown',
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
                      if (_tripDetails?.requester.department != null)
                        Text(
                          _tripDetails!.requester.department,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
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
                          if (_tripDetails?.requester.phone != null &&
                              _tripDetails!.requester.phone!.isNotEmpty)
                            IconButton(
                              onPressed: () => _makePhoneCall(
                                _tripDetails!.requester.phone!,
                              ),
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

  Widget _buildVehicleSection() {
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
                        null)
                      _buildVehicleDetailChip(
                        Icons.local_gas_station,
                        _tripDetails!
                            .details
                            .vehicleDetails
                            .specifications
                            .fuelType,
                      ),
                  ],
                ),
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
          Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
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
                        driver.phone,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
    return Container(
      width: 120,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFFF9C80E), size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
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
                            if (passenger.department != null)
                              Text(
                                passenger.department!,
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

  Widget _buildApprovalSection() {
    if (_tripDetails?.details.approval.hasApproval != true) {
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
          if (_tripDetails?.details.approval.approvers.safety != null)
            _buildApproverRow(
              'Safety Approval',
              _tripDetails!.details.approval.approvers.safety!,
            ),
        ],
      ),
    );
  }

  Widget _buildApproverRow(String label, Approver approver) {
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
              color: _getApprovalStatusColor(approver.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getApprovalStatusIcon(approver.status),
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
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                SizedBox(height: 4),
                if (approver.department != null)
                  Text(
                    approver.department!,
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                SizedBox(height: 4),
                Text(
                  approver.name ?? 'Pending Assignee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (approver.comments != null && approver.comments!.isNotEmpty)
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
              color: _getApprovalStatusColor(approver.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              approver.status.toUpperCase(),
              style: TextStyle(
                color: _getApprovalStatusColor(approver.status),
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

  Widget _buildActionButtons() {
    // Don't show action buttons if viewing from conflict navigation
    /*
    if (widget.fromConflictNavigation) {
      return SizedBox.shrink();
    }
    */

    if (widget.fromInstanceNavigation) {
      return SizedBox.shrink();
    }

    // Only show action buttons for pending trips
    if (_tripDetails?.status != 'pending') {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _showRejectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 8),
                  Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _showApprovalDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
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
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFF9C80E)),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
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
  /*
  Widget _buildScheduleSection() {
    // Only show if it's a scheduled trip
    if (_tripDetails?.schedule.isScheduled == false && _tripDetails?.schedule.isInstance == false ) {
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
                  'Trip #${_tripDetails!.schedule.masterTripId}',
                  () => _navigateToTrip(_tripDetails!.schedule.masterTripId!, false),
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

          // Repetition pattern
          if(!_tripDetails!.schedule.isInstance)
          _buildScheduleInfoRow(
            Icons.repeat,
            'Repetition',
            _tripDetails!.schedule.isInstance
                ? 'Instance of scheduled trip'
                : _tripDetails!.repetition,
            null,
          ),
          SizedBox(height: 8),

          // Valid till date (for master trips)
          if (!_tripDetails!.schedule.isInstance &&
              _tripDetails!.schedule.validTillDate != null)
            Column(
              children: [
                _buildScheduleInfoRow(
                  Icons.calendar_today,
                  'Valid Till',
                  _tripDetails!.schedule.validTillDate!,
                  null,
                ),
                SizedBox(height: 8),
              ],
            ),

          // Include weekends
          if (!_tripDetails!.schedule.isInstance)
            Column(
              children: [
                _buildScheduleInfoRow(
                  Icons.weekend,
                  'Include Weekends',
                  _tripDetails!.schedule.includeWeekends ? 'Yes' : 'No',
                  null,
                ),
                SizedBox(height: 8),
              ],
            ),

          // Repeat after days
          if (!_tripDetails!.schedule.isInstance &&
              _tripDetails!.schedule.repeatAfterDays != null)
            Column(
              children: [
                _buildScheduleInfoRow(
                  Icons.timer,
                  'Repeat After',
                  '${_tripDetails!.schedule.repeatAfterDays} days',
                  null,
                ),
                SizedBox(height: 8),
              ],
            ),

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
                        runSpacing: 8,
                        children: _tripDetails!.schedule.instanceIds!.map((
                          instanceId,
                        ) {
                          return ElevatedButton(
                            onPressed: () => _navigateToTrip(instanceId, true),
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
                                Text('Trip #$instanceId'),
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
                      .where((id) => id != _tripDetails!.id)
                      .map((instanceId) {
                        return ElevatedButton(
                          onPressed: () => _navigateToTrip(instanceId, true),
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
  */

  String _formatDateToMonthDay(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
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
                            onPressed: () => _navigateToTrip(instanceId.id, true),
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
                                Text('Trip ${_formatDateToMonthDay(instanceId.startDate)}'),
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
        builder: (context) =>
            ApprovalDetailsScreen(tripId: tripId, fromInstanceNavigation: isInstance),
      ),
    );
  }

}
