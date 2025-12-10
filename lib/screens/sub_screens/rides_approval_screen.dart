import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/approval_trip_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';

class RidesApprovalScreen extends StatefulWidget {
  const RidesApprovalScreen({super.key});

  @override
  State<RidesApprovalScreen> createState() => _RidesApprovalScreenState();
}

class _RidesApprovalScreenState extends State<RidesApprovalScreen> {
  List<ApprovalTrip> _allTrips = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String _errorMessage = '';
  int _page = 1;
  int _limit = 4;
  bool _hasMore = true;

  // Filters
  String _timeFilter = 'today'; // today, week, month, all
  bool _showReadTrips = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTrips(reset: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_hasMore && !_loadingMore) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadTrips({bool reset = false}) async {
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

      final request = {
        'timeFilter': _timeFilter,
        'page': _page,
        'limit': _limit,
      };

      final response = await ApiService.getTripsForMeterReading(
        request,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        if (reset) {
          setState(() {
            _allTrips = (data['trips'] as List<dynamic>)
                .map((trip) => ApprovalTrip.fromJson(trip))
                .toList();
            _hasMore = data['hasMore'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            final newTrips = (data['trips'] as List<dynamic>)
                .map((trip) => ApprovalTrip.fromJson(trip))
                .toList();
            _allTrips.addAll(newTrips);
            _hasMore = data['hasMore'] ?? false;
            _loadingMore = false;
          });
        }

        setState(() => _errorMessage = '');
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch trips');
      }
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

    setState(() => _page++);
    await _loadTrips(reset: false);
  }

  void _refreshTrips() {
    _loadTrips(reset: true);
  }

  void _setTimeFilter(String filter) {
    setState(() {
      _timeFilter = filter;
      _showReadTrips = false; // Reset to unread when filter changes
    });
    _loadTrips(reset: true);
  }

  // Show/hide read trips toggle only for today filter
  void _toggleShowReadTrips() {
    setState(() => _showReadTrips = !_showReadTrips);
  }

  // Filter trips based on current filter and showReadTrips state
  List<ApprovalTrip> get _filteredTrips {
    if (_timeFilter == 'today') {
      // For Today tab: Separate Need Reading vs Already Read
      return _allTrips.where((trip) {
        if (_showReadTrips) {
          // Show already read today trips
          return trip.hasStartReading || trip.hasEndReading;
        } else {
          // Show trips that need reading today
          return trip.readingTypeNeeded != null;
        }
      }).toList();
    } else {
      // For Week/Month/All tabs: Show ALL trips mixed
      return _allTrips;
    }
  }

  Future<void> _showOdometerDialog(
    ApprovalTrip trip,
    String readingType,
  ) async {
    final readingController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Record ${readingType == 'start' ? 'Start' : 'End'} Odometer',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: readingController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Odometer Reading',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF9C80E)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter odometer reading';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final reading = double.parse(readingController.text);
                  try {
                    final response = await ApiService.recordOdometer(
                      trip.id,
                      reading,
                      readingType,
                    );

                    if (response['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Odometer recorded successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _refreshTrips();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response['message'] ?? 'Failed to record odometer',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF9C80E),
              ),
              child: Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
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

  Widget _buildTripCard(ApprovalTrip trip) {
    final bool needsReading = trip.readingTypeNeeded != null;
    final bool hasDriver =
        trip.driver?.name != null && trip.driver!.name != 'Not Assigned';
    final bool hasPhone =
        trip.driver?.phone != null && trip.driver!.phone!.isNotEmpty;

    return Card(
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
                if (needsReading)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      //color: Color(0xFFF9C80E).withOpacity(0.2),
                      color: trip.readingTypeNeeded == 'start'
                          ? const Color.fromARGB(255, 49, 229, 55).withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEEDS ${trip.readingTypeNeeded!.toUpperCase()} READING',
                      style: TextStyle(
                        //color: Color(0xFFF9C80E),
                        color: trip.readingTypeNeeded == 'start'
                            ? Color.fromARGB(255, 49, 229, 55)
                            : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (trip.isFullyRead)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.yellow),
                        SizedBox(width: 4),
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (trip.hasStartReading || trip.hasEndReading)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'PARTIALLY READ',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                  trip.vehicle?.model ?? 'No Vehicle',
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
                    trip.vehicle?.registrationNumber ?? '',
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

            // Row 3: Driver Info with Call Button
            if (hasDriver)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[400]),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.driver!.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasPhone)
                                Text(
                                  trip.driver!.phone!,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (hasPhone)
                        IconButton(
                          onPressed: () => _callDriver(trip.driver!.phone!),
                          icon: Icon(Icons.phone, color: Colors.green),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),

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
                        'Connected:',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: trip.conflictingTripIds!.map((id) {
                      return Container(
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
                            color: Colors.grey[300],
                            fontSize: 12,
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
                  _formatDate(trip.startDate),
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                SizedBox(width: 8),
                Text(
                  trip.startTime,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Row 6: Meter Reading Button (only for trips that need reading)
            if (needsReading)
              ElevatedButton(
                onPressed: () =>
                    _showOdometerDialog(trip, trip.readingTypeNeeded!),
                style: ElevatedButton.styleFrom(
                  //backgroundColor: Color(0xFFF9C80E),
                  backgroundColor: trip.needsStartReading ? Colors.green : Colors.red,
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  trip.needsStartReading
                      ? 'Record Start Reading'
                      : 'Record End Reading',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Row 7: Reading Status (for trips that have some reading)
            if (trip.hasStartReading)
              Column(
                children: [
                  Divider(color: Colors.grey[700]),
                  // Remove the extra Row and Column that were causing the layout issue
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Start Reading Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Start:',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Padding(
                              padding: EdgeInsets.fromLTRB(18, 2, 0, 0),
                                child: Text(
                                trip.odometerReading?.startReading
                                        ?.toStringAsFixed(0) ??
                                    'Not recorded',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (trip.odometerReading?.startRecordedBy != null)
                              Padding(
                                padding: EdgeInsets.fromLTRB(2, 2, 0, 0),
                                child: Text(
                                  'by: ${trip.odometerReading!.startRecordedBy}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (trip.hasEndReading) 
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[700]!.withOpacity(0.5),
                          margin: EdgeInsets.symmetric(horizontal: 8),
                        ),

                      if (trip.hasEndReading) 
                        // End Reading Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.stop, size: 12, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text(
                                    'End:',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Padding(
                                padding: EdgeInsets.fromLTRB(18, 2, 0, 0),
                                child: Text(
                                  trip.odometerReading?.endReading?.toStringAsFixed(
                                        0,
                                      ) ??
                                      'Not recorded',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (trip.odometerReading?.endRecordedBy != null)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(2, 2, 0, 0),
                                  child: Text(
                                    'by: ${trip.odometerReading!.endRecordedBy}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Optional: Show total distance if both readings exist
                  if (trip.odometerReading?.startReading != null &&
                      trip.odometerReading?.endReading != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.linear_scale,
                            size: 12,
                            color: Color(0xFFF9C80E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Total: ${(trip.odometerReading!.endReading! - trip.odometerReading!.startReading!).toStringAsFixed(0)} km',
                            style: TextStyle(
                              color: Color(0xFFF9C80E),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Add this method for calling driver
  void _callDriver(String phoneNumber) {
    // Use url_launcher package for calling
    // final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    // if (await canLaunchUrl(phoneUri)) {
    //   await launchUrl(phoneUri);
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Cannot make call to $phoneNumber'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling driver: $phoneNumber'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Meter Reading',
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

              // Toggle Button for Today filter only
              if (_timeFilter == 'today')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _showReadTrips = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showReadTrips
                                ? Color(0xFFF9C80E)
                                : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Need Reading',
                            style: TextStyle(
                              color: !_showReadTrips
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _showReadTrips = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showReadTrips
                                ? Color(0xFFF9C80E)
                                : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Already Read',
                            style: TextStyle(
                              color: _showReadTrips
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

          if (_isLoading && _allTrips.isEmpty) _buildLoadingOverlay(),
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
    if (_isLoading && _allTrips.isEmpty) {
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

    final filteredTrips = _filteredTrips;

    if (filteredTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _timeFilter == 'today' && _showReadTrips
                  ? Icons.check_circle_outline
                  : Icons.speed,
              size: 60,
              color: Colors.grey[600],
            ),
            SizedBox(height: 16),
            Text(
              _timeFilter == 'today'
                  ? (_showReadTrips
                        ? 'No read trips for today'
                        : 'No trips need reading today')
                  : 'No trips found',
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
      itemCount: filteredTrips.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < filteredTrips.length) {
          return _buildTripCard(filteredTrips[index]);
        } else {
          return _buildLoadMoreIndicator();
        }
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_loadingMore) {
      return SizedBox.shrink();
    }

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
