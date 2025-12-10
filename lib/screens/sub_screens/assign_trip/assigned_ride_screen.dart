import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/driver_trip_response.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/assign_trip/assign_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';

class AssignedRideScreen extends StatefulWidget {
  final int userId;

  const AssignedRideScreen({super.key, required this.userId});

  @override
  _AssignedRideScreenState createState() => _AssignedRideScreenState();
}

class _AssignedRideScreenState extends State<AssignedRideScreen> {
  List<DriverTripCard> _trips = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String _errorMessage = '';
  int _page = 1;
  int _limit = 6;
  bool _hasMore = true;

  String _timeFilter = 'today';
  String? _statusFilter;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDriverTrips(reset: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverTrips({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _page = 1;
          _hasMore = true;
          _errorMessage = '';
        });
      } else {
        setState(() => _loadingMore = true);
      }

      final request = DriverTripListRequest(
        timeFilter: _timeFilter,
        statusFilter: _statusFilter,
        page: _page,
        limit: _limit,
      );

      final response = await ApiService.getDriverAssignedTrips(request);

      if (mounted) {
        if (reset) {
          setState(() {
            _trips = response.data.trips;
            _hasMore = response.data.hasMore;
            _isLoading = false;
          });
        } else {
          setState(() {
            _trips.addAll(response.data.trips);
            _hasMore = response.data.hasMore;
            _loadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_hasMore && !_loadingMore) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadMoreTrips() async {
    if (!_hasMore || _loadingMore) return;

    setState(() => _page++);
    await _loadDriverTrips(reset: false);
  }

  void _refreshTrips() {
    _loadDriverTrips(reset: true);
  }

  void _setTimeFilter(String filter) {
    if (_timeFilter != filter) {
      setState(() {
        _timeFilter = filter;
        _statusFilter = null; // Reset status filter when time filter changes
      });
      _loadDriverTrips(reset: true);
    }
  }

  void _setStatusFilter(String? filter) {
    if (_statusFilter != filter) {
      setState(() => _statusFilter = filter);
      _loadDriverTrips(reset: true);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'read':
        return Colors.green;
      case 'ongoing':
        return Colors.purple;
      case 'completed':
        return Colors.grey[700]!;
      case 'canceled':
        return Colors.red;
      case 'rejected':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'read':
        return 'READY';
      case 'ongoing':
        return 'ONGOING';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Assigned Rides',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: _refreshTrips,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Time filter buttons
              _buildTimeFilterRow(),

              // Status Filter buttons (only for Today tab) - Wrap version
              if (_timeFilter == 'today')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  color: Colors.black,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Pending button
                      ElevatedButton(
                        onPressed: () => _setStatusFilter('pending'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusFilter == 'pending'
                              ? Color(0xFFF9C80E)
                              : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            color: _statusFilter == 'pending'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Approved button
                      ElevatedButton(
                        onPressed: () => _setStatusFilter('approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusFilter == 'approved'
                              ? Color(0xFFF9C80E)
                              : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'Approved',
                          style: TextStyle(
                            color: _statusFilter == 'approved'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Ongoing button
                      ElevatedButton(
                        onPressed: () => _setStatusFilter('ongoing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusFilter == 'ongoing'
                              ? Color(0xFFF9C80E)
                              : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'Ongoing',
                          style: TextStyle(
                            color: _statusFilter == 'ongoing'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Finished button
                      ElevatedButton(
                        onPressed: () => _setStatusFilter('finished'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusFilter == 'finished'
                              ? Color(0xFFF9C80E)
                              : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'Finished',
                          style: TextStyle(
                            color: _statusFilter == 'finished'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Content
              Expanded(child: _buildContent()),
            ],
          ),

          if (_isLoading && _trips.isEmpty) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTimeFilterRow() {
    final filters = [
      {'label': 'Today', 'value': 'today'},
      {'label': 'Week', 'value': 'week'},
      {'label': 'Month', 'value': 'month'},
      {'label': 'All', 'value': 'all'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: filters.map((filter) {
          final isSelected = _timeFilter == filter['value'];
          return GestureDetector(
            onTap: () => _setTimeFilter(filter['value'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFFF9C80E) : Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _trips.isEmpty) {
      return Container(); // Loading overlay will show
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
                onPressed: _refreshTrips,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF9C80E),
                  foregroundColor: Colors.black,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 60, color: Colors.grey[600]),
            SizedBox(height: 16),
            Text(
              _timeFilter == 'today' && _statusFilter != null
                  ? 'No $_statusFilter trips found for today'
                  : 'No assigned trips found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Try changing your filters',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshTrips(),
      backgroundColor: Colors.black,
      color: Color(0xFFF9C80E),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _trips.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _trips.length) {
            return _buildTripCard(_trips[index]);
          }
          return _buildLoadMoreIndicator();
        },
      ),
    );
  }

  Widget _buildTripCard(DriverTripCard trip) {
      final isGroupTrip =
          trip.conflictingTripIds != null && trip.conflictingTripIds!.isNotEmpty;

      return GestureDetector(
        onTap: () {
          // Navigate to TripDetailsScreen when tapped
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AssignTripDetailsScreen(
                tripId: trip.id,
                fromConflictNavigation: false,
              ),
            ),
          );
        },
        child: Card(
          margin: EdgeInsets.only(bottom: 12),
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Trip ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trip #${trip.id}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trip.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusDisplayText(trip.status),
                        style: TextStyle(
                          color: _getStatusColor(trip.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Row 2: Vehicle Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trip.vehicleModel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trip.vehicleRegNo,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Row 3: Group trip indicator
                if (isGroupTrip)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'Group Trip (${trip.conflictingTripIds!.length + 1} trips)',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isGroupTrip) SizedBox(height: 12),

                // Row 4: Connected Trip IDs (small size)
                if (trip.conflictingTripIds != null &&
                    trip.conflictingTripIds!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, size: 12, color: Colors.grey[400]),
                          SizedBox(width: 4),
                          Text(
                            'Connected Trips:',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: trip.conflictingTripIds!.map((id) {
                          return GestureDetector(
                            onTap: () {
                              // Navigate to the connected trip details
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AssignTripDetailsScreen(
                                    tripId: id,
                                    fromConflictNavigation: true,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '#$id',
                                style: TextStyle(
                                  color:
                                      Colors.blue[300], // Make it look clickable
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),

                // Row 5: Date and Time
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                    SizedBox(width: 8),
                    Text(
                      _formatDate(trip.date),
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                    SizedBox(width: 8),
                    Text(
                      trip.time,
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Row 6: Locations
                if (trip.startLocation != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 12, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trip.startLocation!,
                              style: TextStyle(color: Colors.grey[300]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  ),

                if (trip.endLocation != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 12, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.endLocation!,
                          style: TextStyle(color: Colors.grey[300]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 16),

                // Row 7: Driver assignment and odometer status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (trip.driverAssignment != 'none')
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: trip.isPrimaryDriver
                              ? Colors.green.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: trip.isPrimaryDriver
                                ? Colors.green
                                : Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          trip.isPrimaryDriver
                              ? 'Primary Driver'
                              : 'Secondary Driver',
                          style: TextStyle(
                            color: trip.isPrimaryDriver
                                ? Colors.green
                                : Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    if (trip.odometerStatus != 'none')
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: trip.odometerStatus == 'complete'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.speed,
                              size: 14,
                              color: trip.odometerStatus == 'complete'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              trip.odometerStatus == 'complete'
                                  ? 'Meter Read'
                                  : 'Partial',
                              style: TextStyle(
                                color: trip.odometerStatus == 'complete'
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16),

                // Row 8: Purpose (if available)
                if (trip.purpose != null && trip.purpose!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.purpose!,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Row 9: Details link
                Container(
                  padding: EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[800]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View trip details',
                        style: TextStyle(
                          color: Color(0xFFF9C80E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFFF9C80E),
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
    
  Widget _buildLoadMoreIndicator() {
    if (!_loadingMore) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(color: Color(0xFFF9C80E))),
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
                  'Loading trips...',
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
}
