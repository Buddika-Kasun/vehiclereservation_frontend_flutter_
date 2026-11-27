// lib/features/user_creations/screens/user_creations_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_creation_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/creations/base/base_user_creation_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/creations/widgets/status_filter_buttons.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/creations/widgets/user_creation_card.dart';

class UserCreationsScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Map<String, dynamic>? screenData;

  const UserCreationsScreen({
    Key? key,
    required this.userId,
    required this.token,
    this.screenData,
  }) : super(key: key);

  @override
  _UserCreationsScreenState createState() => _UserCreationsScreenState();
}

class _UserCreationsScreenState
    extends BaseUserCreationListState<UserCreationsScreen> {
  List<Department> _availableDepartments = [];

  String loadingMsg = 'Loading...';

  // Add polling timer for auto-refresh
  Timer? _refreshTimer;
  bool _isRefreshingSilently = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String searchQuery = '';
  bool _hasText = false;

  static const double _componentHeight = 40;

  @override
  void initState() {
    // Apply filter from screenData if available
    if (widget.screenData?['filter'] != null) {
      final filter = widget.screenData!['filter'].toString().toLowerCase();
      if (filter == 'pending') {
        selectedFilter = 'Pending';
      } else if (filter == 'approved') {
        selectedFilter = 'Approved';
      } else if (filter == 'rejected') {
        selectedFilter = 'Rejected';
      }
    }

    super.initState();
    _searchController.addListener(_onTextChanged);
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
        currentPage = 1;
        hasMoreData = true;
        isLoading = true;
      });
      fetchUserCreations(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  String getScreenTitle() => 'User Creations';

  @override
  String getScreenSubtitle() => 'Users where you are the approver';

  @override
  String getEmptyStateMessage() {
    if (searchQuery.isNotEmpty) {
      return 'No users found matching "$searchQuery"';
    }
    if (selectedFilter == 'Pending') {
      return 'No pending requests';
    }
    return 'No ${selectedFilter.toLowerCase()} users';
  }

  @override
  String getLoadingMessage() => 'Loading users...';

  @override
  String getErrorMessage() => 'Error loading users';

  @override
  VoidCallback? getRefreshAction() => refreshUserCreations;

  Future<void> _loadDepartments() async {
    try {
      final response = await ApiService.getDepartments(limit: 50);
      if (response['success'] == true) {
        final List<dynamic> departmentsData =
            response['data']['departments'] ?? [];
        setState(() {
          _availableDepartments = departmentsData
              .map((data) => Department.fromJson(data))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  @override
  Future<void> fetchUserCreations({
    required bool reset,
    bool silent = false,
  }) async {
    try {
      if (reset) {
        setState(() {
          if (!silent) {
            loadingMsg = 'Loading users...';
            isLoading = true;
          }
          currentPage = 1;
          hasMoreData = true;
          if (!silent) {
            allUserCreations = [];
            displayedUserCreations = [];
          }
        });
      } else {
        setState(() => loadingMore = true);
      }

      final response = await ApiService.getUserCreations(
        status: selectedFilter == 'All' ? null : selectedFilter,
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery.isEmpty ? null : searchQuery,
      );

      if (response['success'] == true) {
        final List<dynamic> userCreationsData = response['data']['users'] ?? [];
        final totalCount = response['data']['total'] ?? 0;
        final currentPageNum = response['data']['page'] ?? currentPage;
        final totalPages = response['data']['totalPages'] ?? 1;

        final newUserCreations = userCreationsData
            .map((data) => UserCreation.fromJson(data))
            .toList();

        if (reset) {
          if (silent) {
            updateUserCreationsSilently(
              newUserCreations,
              totalCount,
              currentPageNum < totalPages,
            );
            if (mounted) {
              setState(() {
                errorMessage = '';
              });
            }
          } else {
            setState(() {
              allUserCreations = newUserCreations;
              displayedUserCreations = newUserCreations;
              total = totalCount;
              hasMoreData = currentPageNum < totalPages;
              isLoading = false;
              errorMessage = '';
            });
          }
        } else {
          setState(() {
            allUserCreations.addAll(newUserCreations);
            displayedUserCreations = List.from(allUserCreations);
            hasMoreData = currentPageNum < totalPages;
            loadingMore = false;
            errorMessage = '';
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load user creations');
      }
    } catch (e) {
      print('${getErrorMessage()}: $e');
      setState(() {
        errorMessage = '${getErrorMessage()}: ${e.toString()}';
        isLoading = false;
        loadingMore = false;
      });
    }
  }

  Future<void> _approveUserCreation(
    int index,
    String role,
    String departmentId,
  ) async {
    final userCreation = displayedUserCreations[index];

    try {
      setState(() {
        loadingMsg = 'Processing...';
        isLoading = true;
      });

      final response = await ApiService.approveUserCreationWithDetails(
        userCreation.id,
        role: role,
        departmentId: departmentId,
      );

      if (response['success'] == true) {
        setState(() {
          loadingMsg = 'Loading users...';
        });

        if (mounted) {
          MessageOverlay.showSuccess(
            context: context,
            message: "User approved successfully!",
            duration: const Duration(seconds: 2),
            onComplete: () {},
            position: OverlayPosition.top,
            showBackgroundOverlay: true,
          );
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            selectedFilter = 'Approved';
            expandedIndex = null;
          });
          await fetchUserCreations(reset: true);
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to approve user');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        /*
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to approve user: $e')));
        */
        MessageOverlay.showError(
          context: context,
          message: "Failed to approve user: $e",
          duration: const Duration(seconds: 3),
          showOkButton: true, // Show OK button for errors
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
    }
  }

  Future<void> _rejectUserCreation(int index) async {
    final userCreation = displayedUserCreations[index];

    try {
      setState(() {
        loadingMsg = 'Processing...';
        isLoading = true;
      });

      final response = await ApiService.rejectUserCreation(userCreation.id);

      if (response['success'] == true) {
        setState(() {
          loadingMsg = 'Loading users...';
        });

        if (mounted) {
          MessageOverlay.showSuccess(
            context: context,
            message: "User rejected successfully!",
            duration: const Duration(seconds: 2),
            onComplete: () {},
            position: OverlayPosition.top,
            showBackgroundOverlay: true,
          );
        }
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          selectedFilter = 'Rejected';
          expandedIndex = null;
        });
        await fetchUserCreations(reset: true);
      } else {
        throw Exception(response['message'] ?? 'Failed to reject user');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        MessageOverlay.showError(
          context: context,
          message: "Failed to reject user: $e",
          duration: const Duration(seconds: 3),
          showOkButton: true, // Show OK button for errors
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
        );
      }
    }
  }

  // Create status filters
  List<Map<String, dynamic>> get _statusFilters => [
    {'label': 'Pending', 'value': 'Pending'},
    {'label': 'Approved', 'value': 'Approved'},
    {'label': 'Rejected', 'value': 'Rejected'},
    {'label': 'All', 'value': 'All'},
  ];

  // Search input field with search button (always visible)
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: _componentHeight,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                  if (_hasText)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                      onPressed: _clearSearch,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // SizedBox(width: 8),
          // Container(
          //   height: _componentHeight,
          //   width: _componentHeight,
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFF9C80E),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: IconButton(
          //     icon: const Icon(Icons.search, color: Colors.black, size: 20),
          //     onPressed: () {
          //       // Trigger search immediately
          //       if (_debounceTimer?.isActive ?? false) {
          //         _debounceTimer?.cancel();
          //       }
          //       setState(() {
          //         searchQuery = _searchController.text;
          //         currentPage = 1;
          //         hasMoreData = true;
          //         isLoading = true;
          //       });
          //       fetchUserCreations(reset: true);
          //     },
          //     padding: EdgeInsets.zero,
          //     constraints: const BoxConstraints.expand(),
          //     tooltip: 'Search users',
          //   ),
          // ),
        
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        //isLoading: isLoading && displayedUserCreations.isEmpty,
        isLoading: isLoading,
        loadingMessage: loadingMsg,
        child: Column(
          children: [
            TripHeader(
              title: getScreenTitle(),
              subtitle: getScreenSubtitle(),
              onRefresh: getRefreshAction(),
            ),
            StatusFilterButtons(
              currentFilter: selectedFilter,
              onFilterSelected: (value) => setFilter(value ?? 'Pending'),
              statusFilters: _statusFilters,
            ),
            // Search input field + search button below filter tabs
            _buildSearchSection(),
            // Replace the CountBadge section with this:
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // CountBadge (using your existing widget)
                  CountBadge(totalCount: total, label: '$selectedFilter Users'),
                ],
              ),
            ),
            Expanded(
              child: ListContent<UserCreation>(
                scrollController: scrollController,
                items: displayedUserCreations,
                isLoading: isLoading,
                loadingMore: loadingMore,
                errorMessage: errorMessage,
                hasMore: hasMoreData,
                onRetry: refreshUserCreations,
                emptyStateMessage: getEmptyStateMessage(),
                emptyStateIcon: Icons.people_outline,
                buildItem: (user) {
                  final userCreation = user;
                  final index = displayedUserCreations.indexOf(userCreation);

                  return UserCreationCard(
                    userCreation: userCreation,
                    isExpanded: expandedIndex == index,
                    onTap: () => toggleExpand(index),
                    onApprove: (role, departmentId) =>
                        _approveUserCreation(index, role, departmentId),
                    onReject: () => _rejectUserCreation(index),
                    availableDepartments: _availableDepartments,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
