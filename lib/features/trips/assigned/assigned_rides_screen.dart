import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/mixins/realtime_screen_mixin.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/ride/trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/driver_trip_response.dart';

class AssignedRidesScreen extends StatefulWidget {
  final int userId;

  const AssignedRidesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AssignedRidesScreenState createState() => _AssignedRidesScreenState();
}

class _AssignedRidesScreenState extends State<AssignedRidesScreen> with RealtimeScreenMixin {
  @override
  String get namespace => 'trips';
  
  List<DriverTripCard> _trips = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String _errorMessage = '';
  int _page = 1;
  int _limit = 5;
  bool _hasMore = true;

  // Filters
  String _timeFilter = 'today'; // today, week, month, all
  String? _statusFilter;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAssignedTrips(reset: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void handleScreenRefresh(Map<String, dynamic> data) {
    final scope = data['scope'] ?? 'ALL';
    if (scope == 'TRIPS' || scope == 'ALL' || scope == 'MY_RIDES' || scope == 'ASSIGNED_RIDES') {
      _refreshRides();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToTripDetails(DriverTripCard trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(
          tripId: trip.id,
        ),
      ),
    );
    
    if (result == true) {
      _refreshRides();
    }
  }

  void _refreshRides() {
    _loadAssignedTrips(reset: true);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_loadingMore) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadAssignedTrips({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _page = 1;
          _hasMore = true;
          _trips = [];
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
      
      setState(() => _errorMessage = '');
    } catch (e) {
      print('Error loading assigned trips: $e');
      setState(() {
        _errorMessage = 'Error loading assigned trips: ${e.toString()}';
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMoreTrips() async {
    if (!_hasMore || _loadingMore) return;
    
    setState(() {
      _page++;
    });
    
    await _loadAssignedTrips(reset: false);
  }

  void _setTimeFilter(String filter) {
    setState(() {
      _timeFilter = filter;
      _statusFilter = null;
    });
    _loadAssignedTrips(reset: true);
  }

  void _setStatusFilter(String? status) {
    setState(() {
      _statusFilter = status;
    });
    _loadAssignedTrips(reset: true);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'ongoing': return Colors.blue;
      case 'completed': return Colors.grey[700]!;
      case 'canceled': return Colors.red;
      case 'rejected': return Colors.red[300]!;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    
    if (date.year == today.year && 
        date.month == today.month && 
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && 
               date.month == yesterday.month && 
               date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTimeFilterRow(),
              _buildStatusFilterRow(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
          if (_isLoading && _trips.isEmpty) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Rides',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Trips where you are the driver',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      )
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

  Widget _buildStatusFilterRow() {
    final statuses = [
      {'label': 'All Status', 'value': null},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Approved', 'value': 'approved'},
      {'label': 'Ongoing', 'value': 'ongoing'},
      {'label': 'Completed', 'value': 'completed'},
      {'label': 'Canceled', 'value': 'canceled'},
      {'label': 'Rejected', 'value': 'rejected'},
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _statusFilter,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: Colors.grey[900],
                  style: TextStyle(color: Colors.white),
                  items: statuses.map((status) {
                    return DropdownMenuItem<String?>(
                      value: status['value'] as String?,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          status['label'] as String,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => _setStatusFilter(value),
                  hint: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Filter by status', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _trips.isEmpty) {
      return Container();
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
                onPressed: _refreshRides,
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
              'No assigned trips found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _trips.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _trips.length) {
          return _buildTripCard(_trips[index]);
        } else {
          return _buildLoadMoreIndicator();
        }
      },
    );
  }

  Widget _buildTripCard(DriverTripCard trip) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      child: InkWell(
        onTap: () {
          _navigateToTripDetails(trip);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                     'Trip #' + trip.id.toString(),
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
                      trip.status.toUpperCase(),
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

              Text(
                trip.vehicleModel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                trip.vehicleRegNo,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),

              SizedBox(height: 12),
              
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

              if (trip.startLocation != null || trip.endLocation != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[400], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${trip.startLocation ?? "Unknown"} to ${trip.endLocation ?? "Unknown"}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              SizedBox(height: 12),
              
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Full Details',
                      style: TextStyle(
                        color: Color(0xFFF9C80E),
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFFF9C80E),
                      size: 16,
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
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C80E)),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFF9C80E)),
              SizedBox(height: 16),
              Text(
                'Loading assigned trips...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
