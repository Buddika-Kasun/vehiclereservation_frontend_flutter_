// lib/features/trips/all_trips_(Users)/all_trips_screen.dart

import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_customized_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/time_filter_row.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_management/checklist/checklist_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_management/checklist/widgets/vehicle_checklist_card.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';
import 'package:intl/intl.dart';

class VehicleChecklistsScreen extends StatefulWidget {
  //final UserRole userRole;

  const VehicleChecklistsScreen({
    Key? key, 
    //required this.userRole
  })
    : super(key: key);

  @override
  _VehicleChecklistsScreenState createState() => _VehicleChecklistsScreenState();
}

class _VehicleChecklistsScreenState extends State<VehicleChecklistsScreen> {
  // Common properties
  List<VehicleChecklistResponse> checklists = [];
  int? total;
  int? totalChecklists;
  bool isLoading = true;
  bool loadingMore = false;
  String errorMessage = '';
  String searchQuery = '';
  int page = 1;
  int limit = 10;
  bool hasMore = true;

  // Filters
  String timeFilter = 'today';
  String? statusFilter = 'pending';

  // Controllers
  late ScrollController scrollController;
  bool _isLoadingMore = false;

  // Sort
  String sortField = 'submittedAt';
  String sortOrder = 'asc';

  // Date selection
  String _selectedDate = '';
  bool _isDateSelected = false;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_isLoadingMore) return;

    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100) {
      if (hasMore && !loadingMore && !isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitialData() async {
    await fetchChecklists(reset: true);
  }

  Future<void> fetchChecklists({required bool reset}) async {
    try {
      if (reset) {
        setState(() {
          isLoading = true;
          page = 1;
          hasMore = true;
          checklists = [];
        });
      } else {
        setState(() => loadingMore = true);
      }

      String dateFilter = timeFilter;
      if (_isDateSelected && _selectedDate.isNotEmpty) {
        dateFilter = _selectedDate;
      }

      final request = TripCardListRequest(
        timeFilter: dateFilter,
        statusFilter: statusFilter,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        page: page,
        limit: limit,
        sortField: sortField,
        sortOrder: sortOrder,
      );

      final response = await ApiService.getVehiclesChecklists(request);

      setState(() {
        if (reset) {
          checklists = response.checklists;
        } else {
          checklists.addAll(response.checklists);
        }
        total = response.total;
        totalChecklists = response.totalChecklists;
        hasMore = response.hasMore;
        isLoading = false;
        loadingMore = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading checklists: ${e.toString()}';
        isLoading = false;
        loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!hasMore || loadingMore || isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    setState(() {
      page++;
      loadingMore = true;
    });

    await fetchChecklists(reset: false);
    _isLoadingMore = false;
  }

  void refreshChecklists() {
    setState(() {
      page = 1;
      hasMore = true;
      searchQuery = '';
      isLoading = true;
    });
    fetchChecklists(reset: true);
  }

  void setStatusFilter(String? status) {
    setState(() {
      statusFilter = status;
      page = 1;
      searchQuery = '';
      total = null;
      isLoading = true;
    });
    fetchChecklists(reset: true);
  }

  void setTimeFilter(String? filter) {
    if (filter == 'date') {
      _selectDate();
    } else {
      setState(() {
        _isDateSelected = false;
        _selectedDate = '';
        timeFilter = filter!;
        page = 1;
        searchQuery = '';
        total = null;
        isLoading = true;
      });
      fetchChecklists(reset: true);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFF9C80E),
              onPrimary: Colors.black,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _selectedDate = formattedDate;
        _isDateSelected = true;
        timeFilter = 'date';
        page = 1;
        searchQuery = '';
        total = null;
        isLoading = true;
      });
      fetchChecklists(reset: true);
    } else {
      if (!_isDateSelected) {
        setState(() {
          timeFilter = 'today';
        });
      }
    }
  }

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
      page = 1;
      isLoading = true;
    });
    fetchChecklists(reset: true);
  }

  void _navigateToChecklistDetails(VehicleChecklistResponse checklist) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistDetailsScreen(checklistId: checklist.id),
      ),
    );
    if (result == true) refreshChecklists();
  }

  String _getTimeFilterDisplayText() {
    if (_isDateSelected && _selectedDate.isNotEmpty) {
      try {
        final date = DateTime.parse(_selectedDate);
        return DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        return _selectedDate;
      }
    }
    return 'Today';
  }

  String getDynamicEmptyStateMessage() {
    if (searchQuery.isNotEmpty) {
      return 'No checklists found matching "$searchQuery"';
    }
    return 'No review checklists found';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              TripHeader(
                title: 'Vehicles Checklists',
                subtitle: 'Explore vehicles checklists',
                onRefresh: refreshChecklists,
              ),
              /*
              TimeFilterRow(
                currentFilter: timeFilter,
                onFilterSelected: setTimeFilter,
                filters: [
                  {'label': 'Today', 'value': 'today'},
                  {'label': 'Select Date', 'value': 'date'},
                ],
                selectedDate: _isDateSelected ? _selectedDate : null,
              ),
              */
              StatusFilterDropdownCustomized(
                currentFilter: timeFilter,
                onFilterSelected: setTimeFilter,
                onSearch: _handleSearch,
                enableSearch: true,
                statusFilters: [
                  {'label': 'Today', 'value': 'today'},
                  {'label': 'Select Date', 'value': 'date'},
                ],
                selectedDate: _isDateSelected ? _selectedDate : null,
              ),

              SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CountBadge(totalCount: total, label: "Vehicles"),
                    const Spacer(),
                    CountBadge(totalCount: totalChecklists, label: "Checklists",)
                    // Add sort button if needed
                  ],
                ),
              ),

              if (!_isDateSelected && !_selectedDate.isNotEmpty)
                const SizedBox(height: 8),

              if (_isDateSelected && _selectedDate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9C80E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF9C80E).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: const Color(0xFFF9C80E),
                        ),
                        Text(
                          'Showing checklists for: ${_getTimeFilterDisplayText()}',
                          style: TextStyle(
                            color: const Color(0xFFF9C80E),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDateSelected = false;
                              _selectedDate = '';
                              timeFilter = 'today';
                              page = 1;
                              total = null;
                              isLoading = true;
                            });
                            fetchChecklists(reset: true);
                          },
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: const Color(0xFFF9C80E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 50,
                            ),
                            SizedBox(height: 16),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: refreshChecklists,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF9C80E),
                                foregroundColor: Colors.black,
                              ),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : checklists.isEmpty && !isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in,
                              color: Colors.grey[600],
                              size: 50,
                            ),
                            SizedBox(height: 16),
                            Text(
                              getDynamicEmptyStateMessage(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: checklists.length + (loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == checklists.length && loadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF9C80E),
                                ),
                              ),
                            );
                          }
                          return VehicleChecklistCard(
                            checklist: checklists[index],
                            onTap: () =>
                                _navigateToChecklistDetails(checklists[index]),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Loading overlay - only shows when isLoading is true AND checklists is empty
          if (isLoading && checklists.isEmpty)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFF9C80E)),
                    const SizedBox(height: 16),
                    Text(
                      'Loading checklists...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Loading more indicator at bottom (already handled in ListView)
        ],
      ),
    );
  }
}
