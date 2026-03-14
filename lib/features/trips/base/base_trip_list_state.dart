// lib/features/trips/base/base_trip_list_state.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/sort_enums.dart';

abstract class BaseTripListState<T extends StatefulWidget> extends State<T> {
  // Common properties
  List<TripCardModel> trips = [];
  int? total;
  bool isLoading = true;
  bool loadingMore = false;
  String errorMessage = '';
  String searchQuery = '';
  int page = 1;
  int limit = 10;
  bool hasMore = true;

  // Add this to prevent multiple load more calls
  bool _isLoadingMore = false;

  // Filters
  String timeFilter = 'today';
  String? statusFilter;

  // Controllers
  late ScrollController scrollController;

  // Refresh timer
  Timer? refreshTimer;
  bool isRefreshingSilently = false;
  Timer? debounceTimer;

  // Cache for silent refresh comparison
  List<TripCardModel> _cachedTrips = [];

  Timer? _searchDebounceTimer;
  bool _isSearching = false;

  // Callbacks for dropdown reset (to be implemented by child classes if needed)
  VoidCallback? onRegularDropdownReset;
  VoidCallback? onCustomizedDropdownReset;

  SortField sortField = SortField.startTime; // Default sort by start time
  SortOrder sortOrder = SortOrder.desc; // Default descending (newest first)

  // Abstract methods that must be implemented
  Future<void> fetchTrips({required bool reset, bool silent = false});
  String getScreenTitle();
  String getScreenSubtitle();
  String getEmptyStateMessage();
  String getLoadingMessage();
  String getErrorMessage();
  VoidCallback? getRefreshAction();
  //SortField get sortField => sortField;
  //SortOrder get sortOrder => _sortOrder;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_scrollListener);
    _loadInitialData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    scrollController.dispose();
    debounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _stopAutoRefresh();
    super.dispose();
  }

  // Common methods
  void _loadInitialData() {
    fetchTrips(reset: true);
  }

  void _startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isRefreshingSilently && mounted) {
        _silentRefresh();
      }
    });
  }

  void _stopAutoRefresh() {
    refreshTimer?.cancel();
    refreshTimer = null;
  }

  Future<void> _silentRefresh() async {
    if (isRefreshingSilently || !mounted) return;

    try {
      isRefreshingSilently = true;

      if (page == 1) {
        // Cache current trips BEFORE calling fetchTrips
        _cachedTrips = List.from(trips);
        await fetchTrips(reset: true, silent: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Silent refresh error: $e');
      }
    } finally {
      isRefreshingSilently = false;
    }
  }

  void _scrollListener() {
    // Only trigger if we're not already loading more
    if (_isLoadingMore) return;

    // Check if we're near the bottom (within 100 pixels)
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100) {
      if (hasMore && !loadingMore && !isLoading) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadMoreTrips() async {
    if (!hasMore || loadingMore || isLoading || _isLoadingMore) return;

    _isLoadingMore = true;

    setState(() {
      page++;
      loadingMore = true;
    });

    await fetchTrips(reset: false);

    _isLoadingMore = false;
  }

  void refreshTrips() {
    setState(() {
      page = 1;
      hasMore = true;
      searchQuery = ''; // Clear search on manual refresh
    });
    fetchTrips(reset: true);
  }

  void debounceRefresh() {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        refreshTrips();
      }
    });
  }

  // Updated setTimeFilter with search reset using callbacks
  void setTimeFilter(String filter) {
    onRegularDropdownReset?.call();
    onCustomizedDropdownReset?.call();

    setState(() {
      searchQuery = ''; // Clear search when changing filter
      sortField = SortField.startTime;
      sortOrder = SortOrder.desc;
      timeFilter = filter;
      total = null;
      page = 1;
    });
    fetchTrips(reset: true);
  }

  void setStatusFilter(String? status) {
    setState(() {
      statusFilter = status;
      page = 1;
      searchQuery = ''; // Clear search when changing filter
      total = null;
    });
    fetchTrips(reset: true);
  }

  // Debounced search method
  void setSearchQueryDebounced(String query) {
    // Cancel any pending search timer
    _searchDebounceTimer?.cancel();

    // Update search query immediately in state (for UI)
    setState(() {
      searchQuery = query;
    });

    // If query is empty, search immediately
    if (query.isEmpty) {
      setState(() {
        page = 1;
        hasMore = true;
        trips = [];
        isLoading = true;
      });
      fetchTrips(reset: true);
      return;
    }

    // Otherwise, debounce the actual search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          page = 1;
          hasMore = true;
          trips = [];
          isLoading = true;
        });
        fetchTrips(reset: true);
      }
    });
  }

  // Clear search
  void clearSearch() {
    _searchDebounceTimer?.cancel();
    if (searchQuery.isNotEmpty) {
      setState(() {
        searchQuery = '';
        page = 1;
        hasMore = true;
        trips = [];
        isLoading = true;
      });
      fetchTrips(reset: true);
    }
  }

  // Enhanced data change detection with full comparison
  bool hasDataChanged(
    List<TripCardModel> newTrips, [
    List<TripCardModel>? oldTrips,
  ]) {
    final compareTrips = oldTrips ?? _cachedTrips;

    // If no cached trips available, assume data changed
    if (compareTrips.isEmpty && newTrips.isNotEmpty) return true;
    if (compareTrips.isEmpty && newTrips.isEmpty) return false;

    if (compareTrips.length != newTrips.length) return true;

    for (int i = 0; i < newTrips.length; i++) {
      final newTrip = newTrips[i];
      final oldTrip = compareTrips[i];

      // Compare all relevant fields that affect UI
      if (newTrip.id != oldTrip.id ||
          newTrip.status != oldTrip.status ||
          newTrip.requesterName != oldTrip.requesterName ||
          newTrip.vehicleModel != oldTrip.vehicleModel ||
          newTrip.vehicleRegNo != oldTrip.vehicleRegNo ||
          newTrip.startLocation != oldTrip.startLocation ||
          newTrip.endLocation != oldTrip.endLocation ||
          newTrip.date != oldTrip.date ||
          newTrip.time != oldTrip.time) {
        return true;
      }
    }

    return false;
  }

  // Helper method for silent refresh to update UI only when data changes
  void updateTripsSilently(
    List<TripCardModel> newTrips,
    bool newHasMore,
    int? newTotal,
  ) {
    if (!mounted) return;

    // Don't update if both are empty
    if (_cachedTrips.isEmpty && newTrips.isEmpty) {
      if (kDebugMode) {
        print('🔄 Silent refresh: Both empty, no update needed');
      }
      _cachedTrips = [];
      return;
    }

    // Compare with cached trips from before the silent refresh
    if (hasDataChanged(newTrips, _cachedTrips)) {
      if (kDebugMode) {
        print('🔄 Silent refresh: Data changed, updating UI');
        print(
          '   Old count: ${_cachedTrips.length}, New count: ${newTrips.length}',
        );
      }
      setState(() {
        trips = newTrips;
        hasMore = newHasMore;
        total = newTotal;
        // Don't touch isLoading state
      });
    } else {
      if (kDebugMode) {
        print('🔄 Silent refresh: No changes detected');
      }
    }

    // Clear cache after comparison
    _cachedTrips = [];
  }

  // Helper to get dynamic empty state message
  String getDynamicEmptyStateMessage() {
    if (searchQuery.isNotEmpty) {
      return 'No trips found matching "$searchQuery"';
    }
    return getEmptyStateMessage();
  }

  // Helper to get dynamic badge label
  String getDynamicBadgeLabel() {
    if (searchQuery.isNotEmpty) {
      return 'Search Results';
    }
    return '${_getStatusLabel(statusFilter)} Trips';
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'All';
    return status[0].toUpperCase() + status.substring(1);
  }

  // Helper to build search indicator (can be used by child classes)
  Widget buildSearchIndicator() {
    if (searchQuery.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFFF9C80E), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Searching: "$searchQuery"',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[400], size: 16),
            onPressed: clearSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Clear search',
          ),
        ],
      ),
    );
  }

  // Sort method
  void setSort(SortField field, SortOrder order) {
    setState(() {
      sortField = field;
      sortOrder = order;
      page = 1;
      trips = [];
      isLoading = true;
    });
    fetchTrips(reset: true);
  }

  // Toggle sort order for current field
  void toggleSortOrder() {
    setState(() {
      sortOrder = sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
      page = 1;
      trips = [];
      isLoading = true;
    });
    fetchTrips(reset: true);
  }

  // Change sort field
  void changeSortField(SortField field) {
    setState(() {
      sortField = field;
      page = 1;
      trips = [];
      isLoading = true;
    });
    fetchTrips(reset: true);
  }
  
}
