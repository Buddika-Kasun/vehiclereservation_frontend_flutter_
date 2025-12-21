import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/ride/trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/driver_trip_response.dart';
import 'package:flutter/foundation.dart';

// Import new WebSocket structure
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/websocket_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/ws/handlers/trip_handler.dart';

class AssignedRidesScreen extends StatefulWidget {
  final int userId;

  const AssignedRidesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AssignedRidesScreenState createState() => _AssignedRidesScreenState();
}

class _AssignedRidesScreenState extends State<AssignedRidesScreen> {
  // WebSocket managers
  final WebSocketManager _webSocketManager = WebSocketManager();
  final TripHandler _tripHandler = TripHandler();

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

  // WebSocket connection state
  bool _isConnected = false;
  bool _isInitializing = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAssignedTrips(reset: true);
    _scrollController.addListener(_scrollListener);
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

      // Get token and userId from storage (you need to implement this)
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
          print('🔌 AssignedRidesScreen connection: $isConnected');
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
        print('❌ AssignedRidesScreen WebSocket error: $e');
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
      print('📨 AssignedRidesScreen received event: $event');
    }

    // Handle refresh events
    if (event == 'refresh') {
      _handleRefreshEvent(data);
    }
  }

  void _handleTripUpdate(Map<String, dynamic> update) {
    final type = update['type']?.toString() ?? '';
    final scope = update['scope']?.toString() ?? '';

    if (kDebugMode) {
      print('🔄 Trip update received: $type, scope: $scope');
    }

    // Only refresh if scope is relevant to assigned rides
    if (scope == 'TRIPS' ||
        scope == 'ALL' ||
        scope == 'MY_RIDES' ||
        scope == 'ASSIGNED_RIDES') {
      _debounceRefresh();
    }
  }

  void _handleRefreshEvent(Map<String, dynamic> data) {
    final scope = data['scope']?.toString() ?? 'ALL';

    if (kDebugMode) {
      print('🔄 Refresh event received, scope: $scope');
    }

    // Only refresh if scope is relevant to assigned rides
    if (scope == 'TRIPS' ||
        scope == 'ALL' ||
        scope == 'MY_RIDES' ||
        scope == 'ASSIGNED_RIDES') {
      _debounceRefresh();
    }
  }

  void _debounceRefresh() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _refreshRides();
      }
    });
  }

  void _navigateToTripDetails(DriverTripCard trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(tripId: trip.id),
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
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
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

  // Helper methods to get token and userId (you need to implement these)
  Future<String?> _getToken() async {
    // Implement token retrieval from storage
    // Example: return await SecureStorageService().accessToken;
    return null;
  }

  Future<String?> _getUserId() async {
    // Implement userId retrieval from storage
    // Example: final user = StorageService.userData; return user?.id.toString();
    return null;
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
              Expanded(child: _buildContent()),
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
          Row(
            children: [
              Text(
                'Assigned Rides',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
          Text(
            'Trips where you are the driver',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
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
                    child: Text(
                      'Filter by status',
                      style: TextStyle(color: Colors.grey),
                    ),
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
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                  border: Border(top: BorderSide(color: Colors.grey[700]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Full Details',
                      style: TextStyle(color: Color(0xFFF9C80E), fontSize: 14),
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
      child: Center(child: CircularProgressIndicator(color: Color(0xFFF9C80E))),
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
              if (_isInitializing)
                CircularProgressIndicator(color: Color(0xFFF9C80E)),
              SizedBox(height: 16),
              Text(
                _isInitializing
                    ? 'Connecting to real-time updates...'
                    : 'Loading assigned trips...',
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
    );
  }
}
