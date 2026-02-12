// lib/features/trips/base/base_trip_list_state.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';

abstract class BaseTripListState<T extends StatefulWidget> extends State<T> {
  // Common properties
  List<TripCardModel> trips = [];
  bool isLoading = true;
  bool loadingMore = false;
  String errorMessage = '';
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

  // Abstract methods that must be implemented
  Future<void> fetchTrips({required bool reset, bool silent = false});
  String getScreenTitle();
  String getScreenSubtitle();
  VoidCallback? getRefreshAction();

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
    if (scrollController.position.pixels >=
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

  void setTimeFilter(String filter) {
    setState(() {
      timeFilter = filter;
      statusFilter = null;
      page = 1;
    });
    fetchTrips(reset: true);
  }

  void setStatusFilter(String? status) {
    setState(() {
      statusFilter = status;
      page = 1;
    });
    fetchTrips(reset: true);
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
  void updateTripsSilently(List<TripCardModel> newTrips, bool newHasMore) {
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

}
