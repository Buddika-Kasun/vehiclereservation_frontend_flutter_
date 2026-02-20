// lib/features/user_creations/base/base_user_creation_list_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_creation_model.dart';

abstract class BaseUserCreationListState<T extends StatefulWidget>
    extends State<T> {
  // Common properties
  List<UserCreation> allUserCreations = [];
  List<UserCreation> displayedUserCreations = [];

  bool isLoading = true;
  bool loadingMore = false;
  String errorMessage = '';
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool hasMoreData = true;

  // Add this to prevent multiple load more calls
  bool _isLoadingMore = false;

  // Filters
  String selectedFilter = 'Pending'; // 'Pending', 'Approved', 'Rejected', 'All'
  int? total;

  // Controllers
  late ScrollController scrollController;

  // Refresh timer
  Timer? refreshTimer;
  bool isRefreshingSilently = false;
  Timer? debounceTimer;

  // Cache for silent refresh comparison
  List<UserCreation> _cachedUserCreations = [];

  // Expanded state
  int? expandedIndex;

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

  // Abstract methods
  Future<void> fetchUserCreations({required bool reset, bool silent = false});
  String getScreenTitle();
  String getScreenSubtitle();
  String getEmptyStateMessage();
  String getLoadingMessage();
  String getErrorMessage();
  VoidCallback? getRefreshAction();

  void _loadInitialData() {
    fetchUserCreations(reset: true);
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

      if (currentPage == 1) {
        // Cache current items BEFORE calling fetch
        _cachedUserCreations = List.from(allUserCreations);
        await fetchUserCreations(reset: true, silent: true);
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
    if (_isLoadingMore) return;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (hasMoreData && !loadingMore && !isLoading) {
        _loadMoreUserCreations();
      }
    }
  }

  Future<void> _loadMoreUserCreations() async {
    if (!hasMoreData || loadingMore || isLoading || _isLoadingMore) return;

    _isLoadingMore = true;

    setState(() {
      currentPage++;
      loadingMore = true;
    });

    await fetchUserCreations(reset: false);

    _isLoadingMore = false;
  }

  void refreshUserCreations() {
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      expandedIndex = null; // Collapse all on refresh
    });
    fetchUserCreations(reset: true);
  }

  void debounceRefresh() {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        refreshUserCreations();
      }
    });
  }

  void setFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      currentPage = 1;
      total = null;
      expandedIndex = null; // Collapse all on filter change
    });
    fetchUserCreations(reset: true);
  }

  // Data change detection
  bool hasDataChanged(
    List<UserCreation> newList, [
    List<UserCreation>? oldList,
  ]) {
    final compareList = oldList ?? _cachedUserCreations;

    if (compareList.isEmpty && newList.isNotEmpty) return true;
    if (compareList.isEmpty && newList.isEmpty) return false;
    if (compareList.length != newList.length) return true;

    for (int i = 0; i < newList.length; i++) {
      final newItem = newList[i];
      final oldItem = compareList[i];

      if (newItem.id != oldItem.id ||
          newItem.isApproved != oldItem.isApproved ||
          newItem.updatedAt != oldItem.updatedAt) {
        return true;
      }
    }

    return false;
  }

  // Helper method for silent refresh
  void updateUserCreationsSilently(
    List<UserCreation> newList,
    int newTotal,
    bool newHasMore,
  ) {
    if (!mounted) return;

    if (_cachedUserCreations.isEmpty && newList.isEmpty) {
      if (kDebugMode) {
        print('🔄 Silent refresh: Both empty, no update needed');
      }
      _cachedUserCreations = [];
      return;
    }

    if (hasDataChanged(newList, _cachedUserCreations)) {
      if (kDebugMode) {
        print('🔄 Silent refresh: Data changed, updating UI');
        print(
          '   Old count: ${_cachedUserCreations.length}, New count: ${newList.length}',
        );
      }
      setState(() {
        allUserCreations = newList;
        displayedUserCreations = newList;
        total = newTotal;
        hasMoreData = newHasMore;
        // Keep expanded state but it might be invalid if items changed
        if (expandedIndex != null && expandedIndex! >= newList.length) {
          expandedIndex = null;
        }
      });
    } else {
      if (kDebugMode) {
        print('🔄 Silent refresh: No changes detected');
      }
    }

    _cachedUserCreations = [];
  }

  void toggleExpand(int index) {
    setState(() {
      if (expandedIndex == index) {
        expandedIndex = null;
      } else {
        expandedIndex = index;
      }
    });
  }
}
