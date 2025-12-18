import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/approval/approval_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/approval_model.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({Key? key}) : super(key: key);

  @override
  _ApprovalsScreenState createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<ApprovalTrip> _trips = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String _errorMessage = '';
  int _page = 1;
  int _limit = 4;
  bool _hasMore = true;

  // Filters - Changed to pending, approved, rejected, all
  String _statusFilter = 'pending'; // pending, approved, rejected, all

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadApprovals(reset: true);
    
    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_loadingMore) {
        _loadMoreApprovals();
      }
    }
  }

  Future<void> _loadApprovals({bool reset = false}) async {
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
      
      // Create request with status filter
      final request = {
        'status': _statusFilter,
        'page': _page,
        'limit': _limit,
      };
      
      final response = await ApiService.getPendingApprovals(request);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final tripsData = data['trips'] as List<dynamic>? ?? [];
        
        if (reset) {
          setState(() {
            _trips = tripsData.map((trip) => ApprovalTrip.fromJson(trip)).toList();
            _hasMore = data['hasMore'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _trips.addAll(tripsData.map((trip) => ApprovalTrip.fromJson(trip)).toList());
            _hasMore = data['hasMore'] ?? false;
            _loadingMore = false;
          });
        }
        
        setState(() => _errorMessage = '');
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch approvals');
      }
    } catch (e) {
      //print('Error loading approvals: $e');
      setState(() {
        _errorMessage = 'Error loading approvals: ${e.toString()}';
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMoreApprovals() async {
    if (!_hasMore || _loadingMore) return;
    
    setState(() {
      _page++;
    });
    
    await _loadApprovals(reset: false);
  }

  void _refreshApprovals() {
    _loadApprovals(reset: true);
  }

  void _setStatusFilter(String filter) {
    setState(() {
      _statusFilter = filter;
    });
    _loadApprovals(reset: true);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
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

  void _navigateToApprovalDetails(ApprovalTrip trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApprovalDetailsScreen(
          tripId: trip.id,
        ),
      ),
    );
    
    // Check if we need to refresh the list
    if (result == true) {
      _refreshApprovals(); // Refresh the list
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
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Approvals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Approve or reject trip requests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
              // Status filter buttons (replacing time filter)
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

  Widget _buildStatusFilterRow() {
    final filters = [
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Approved', 'value': 'approved'},
      {'label': 'Rejected', 'value': 'rejected'},
      {'label': 'All', 'value': 'all'},
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: filters.map((filter) {
          final isSelected = _statusFilter == filter['value'];
          return GestureDetector(
            onTap: () => _setStatusFilter(filter['value'] as String),
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
                onPressed: _refreshApprovals,
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
            Icon(Icons.checklist_rtl, size: 60, color: Colors.grey[600]),
            SizedBox(height: 16),
            Text(
              'No approvals found',
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
          return _buildApprovalCard(_trips[index]);
        } else {
          return _buildLoadMoreIndicator();
        }
      },
    );
  }

  Widget _buildApprovalCard(ApprovalTrip trip) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      child: InkWell(
        onTap: () {
          // Navigate to approval details screen
          _navigateToApprovalDetails(trip);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 0: Trip id + Status label
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

              // Row 1: Requester name and vehicle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip.requesterName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              
              // Row 2: Date + Time
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                  SizedBox(width: 8),
                  Text(
                    _formatDate(trip.startDate),
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                  SizedBox(width: 8),
                  Text(
                    trip.startTime.substring(0, 5), // Format to HH:MM
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Row 3: Route
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.startLocation,
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.endLocation,
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  'Loading approvals...',
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
