import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_list_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/review/review_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/ride/trip_details_screen.dart';

class ReviewTripScreen extends StatefulWidget {
  final int userId;

  const ReviewTripScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ReviewTripScreenState createState() => _ReviewTripScreenState();
}

class _ReviewTripScreenState extends State<ReviewTripScreen> {
  List<TripCard> _trips = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String _errorMessage = '';
  int _page = 1;
  int _limit = 3;
  bool _hasMore = true;

  // Filters
  TimeFilter _timeFilter = TimeFilter.today; // today, week, month, all
  TripStatus? _statusFilter = TripStatus.draft;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserTrips(reset: true);
    
    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToTripDetails(trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewTripDetailsScreen(
          tripId: trip.id,
        ),
      ),
    );
    
    // Check if we need to refresh the list
    if (result == true) {
      _refreshRides(); // Refresh the list
    }
  }

  void _refreshRides() {
    _loadUserTrips(reset: true);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_loadingMore) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadUserTrips({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _page = 1;
          _hasMore = true;
        });
      } else {
        setState(() => _loadingMore = true);
      }
      
      final request = TripListRequest(
        timeFilter: _timeFilter,
        statusFilter: _statusFilter,
        page: _page,
        limit: _limit,
      );
      
      final response = await ApiService.getSupervisorTrips(request);
      
      if (reset) {
        setState(() {
          _trips = response.trips;
          _hasMore = response.hasMore;
          _isLoading = false;
        });
      } else {
        setState(() {
          _trips.addAll(response.trips);
          _hasMore = response.hasMore;
          _loadingMore = false;
        });
      }
      
      setState(() => _errorMessage = '');
    } catch (e) {
      print('Error loading trips: $e');
      setState(() {
        _errorMessage = 'Error loading trips: ${e.toString()}';
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
    
    await _loadUserTrips(reset: false);
  }

  void _refreshTrips() {
    _loadUserTrips(reset: true);
  }

  void _setTimeFilter(TimeFilter filter) {
    setState(() {
      _timeFilter = filter;
      if(filter == TimeFilter.today) {
        _statusFilter = TripStatus.draft;
      }
      else {
        _statusFilter = null;
      }
    });
    _loadUserTrips(reset: true);
  }

  void _setStatusFilter(TripStatus? status) {
    setState(() {
      _statusFilter = status;
    });
    _loadUserTrips(reset: true);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'ongoing': return Colors.blue;
      case 'completed': return Colors.grey[700]!;
      case 'canceled': return Colors.red;
      case 'rejected': return Colors.red[300]!;
      case 'draft': return Colors.deepOrangeAccent;
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
              // Header
              _buildHeader(),
              
              // Time filter buttons
              _buildTimeFilterRow(),
              
              // Status filter dropdown
              if(_timeFilter == TimeFilter.today)
                _buildStatusFilterRow(),
              
              // Content
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
            'Review Trips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      )
    );
        
  }

  Widget _buildTimeFilterRow() {
    final filters = [
      {'label': 'Today', 'value': TimeFilter.today},
      {'label': 'Week', 'value': TimeFilter.week},
      {'label': 'Month', 'value': TimeFilter.month},
      {'label': 'All', 'value': TimeFilter.all},
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: filters.map((filter) {
          final isSelected = _timeFilter == filter['value'];
          return GestureDetector(
            onTap: () => _setTimeFilter(filter['value'] as TimeFilter),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          // Pending Button
          Expanded(
            child: GestureDetector(
              onTap: () => _setStatusFilter(TripStatus.draft),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _statusFilter == TripStatus.draft
                      ? Colors.yellow[600]
                      : Colors.grey[900],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Draft',
                  style: TextStyle(
                    color: _statusFilter == TripStatus.draft
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Reviewed Button
          Expanded(
            child: GestureDetector(
              onTap: () => _setStatusFilter(null), // Show all trips (reviewed)
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _statusFilter == null
                      ? Colors.yellow[600]
                      : Colors.grey[900],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                alignment: Alignment.center,
                child: Text(
                  'All',
                  style: TextStyle(
                    color: _statusFilter == null ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
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
              'No trips found',
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

  Widget _buildTripCard(TripCard trip) {
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
              // Row 0: Trip id + Type label + Status label
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
                  
                  //SizedBox(width: 12),

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

              // Row 1: Vehicle model
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    //trip.vehicleModel,
                    trip.vehicleModel != 'Unknown'
                    ? '${trip.vehicleModel}'
                    : 'Supervisor under reviewing...'
                    ,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (trip.vehicleModel != 'Unknown')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
              
              // Row 3: Date + Time
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
              
              // Row 4: Click for more details
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
                      'Click for more details',
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
    if (!_loadingMore) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF9C80E),
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
                  'Loading trips...',
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