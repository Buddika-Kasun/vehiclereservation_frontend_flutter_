// lib/features/trips/review_(Supervisor)/review_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/base/base_trip_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/review_(Supervisors)/review_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/sort_enums.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/sort_button.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_customized_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/time_filter_row.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';
import 'package:intl/intl.dart';

class ReviewTripScreen extends StatefulWidget {
  final int userId;

  const ReviewTripScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ReviewTripScreenState createState() => _ReviewTripScreenState();
}

class _ReviewTripScreenState extends BaseTripListState<ReviewTripScreen> {
  @override
  void initState() {
    statusFilter = 'draft';
    super.initState();
  }

  @override
  String getScreenTitle() => 'Review Trips';

  @override
  String getScreenSubtitle() => 'Trips where you are the supervisor';

  @override
  String getEmptyStateMessage() => 'No trips found';

  @override
  String getLoadingMessage() => 'Loading trips...';

  @override
  String getErrorMessage() => 'Error loading trips';

  @override
  VoidCallback? getRefreshAction() => refreshTrips;

  @override
  Future<void> fetchTrips({required bool reset, bool silent = false}) async {
    try {
      if (reset) {
        setState(() {
          if (!silent) {
            isLoading = true;
          }
          page = 1;
          hasMore = true;
          // Don't clear trips array during silent refresh
          if (!silent) {
            trips = [];
          }
        });
      } else {
        setState(() => loadingMore = true);
      }

      // Apply date filter
      String dateFilter = timeFilter;
      if (isDateSelected && selectedDate.isNotEmpty) {
        dateFilter = selectedDate;
      }

      final request = TripCardListRequest(
        timeFilter: dateFilter,
        statusFilter: statusFilter,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        sortField: sortField.name,
        sortOrder: sortOrder.name,
        page: page,
        limit: limit,
      );

      final response = await ApiService.getSupervisorTripsNew(request);

      final newTrips = response.data.trips;
      final newTotal = response.data.total;

      if (reset) {
        if (silent) {
          // Use the helper method for silent updates
          updateTripsSilently(newTrips, response.data.hasMore, newTotal);
          if (mounted) {
            setState(() {
              errorMessage = '';
            });
          }
        } else {
          setState(() {
            trips = newTrips;
            total = newTotal;
            hasMore = response.data.hasMore;
            isLoading = false;
            errorMessage = '';
          });
        }
      } else {
        setState(() {
          trips.addAll(newTrips);
          hasMore = response.data.hasMore;
          loadingMore = false;
          errorMessage = '';
        });
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

  @override
  void setTimeFilter(String filter) {
    if (filter == 'date') {
      _selectDate();
    } else {
      setState(() {
        isDateSelected = false;
        selectedDate = '';
        searchQuery = '';
        timeFilter = filter;
        sortField = SortField.startTime;
        sortOrder = filter == 'today' ? SortOrder.asc : SortOrder.desc;
        total = null;
        if (timeFilter == 'today') {
          statusFilter = 'draft';
        } else {
          statusFilter = null;
        }
        page = 1;
      });
      fetchTrips(reset: true);
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
        selectedDate = formattedDate;
        isDateSelected = true;
        timeFilter = 'date';
        page = 1;
        searchQuery = '';
        total = null;
        sortField = SortField.startTime;
        sortOrder = SortOrder.asc;
        // Reset status filter when selecting a specific date
        statusFilter = null;
      });
      fetchTrips(reset: true);
    } else {
      // If user cancels date selection and no date was previously selected,
      // revert to 'today'
      if (!isDateSelected) {
        setState(() {
          timeFilter = 'today';
          statusFilter = 'draft';
        });
      }
    }
  }

  String _getTimeFilterDisplayText() {
    if (isDateSelected && selectedDate.isNotEmpty) {
      try {
        final date = DateTime.parse(selectedDate);
        return DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        return selectedDate;
      }
    }
    return 'Today';
  }

  void _handleSearch(String query) {
    setSearchQueryDebounced(query);
  }

  void _navigateToTripDetails(TripCardModel trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewTripDetailsScreen(tripId: trip.id),
      ),
    );

    if (result == true) {
      refreshTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        isLoading: isLoading && trips.isEmpty,
        loadingMessage: getLoadingMessage(),
        child: Column(
          children: [
            TripHeader(
              title: getScreenTitle(),
              subtitle: getScreenSubtitle(),
              onRefresh: getRefreshAction(),
            ),
            TimeFilterRow(
              currentFilter: timeFilter,
              onFilterSelected: setTimeFilter,
              filters: [
                {'label': 'Today', 'value': 'today'},
                {'label': 'Week', 'value': 'week'},
                {'label': 'Date', 'value': 'date'},
                {'label': 'All', 'value': 'all'},
              ],
              selectedDate: isDateSelected ? selectedDate : null,
            ),

            // Date indicator - shows when a specific date is selected
            if (isDateSelected && selectedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                        'Showing trips for: ${_getTimeFilterDisplayText()}',
                        style: TextStyle(
                          color: const Color(0xFFF9C80E),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isDateSelected = false;
                            selectedDate = '';
                            timeFilter = 'today';
                            page = 1;
                            total = null;
                            statusFilter = 'draft';
                            sortField = SortField.startTime;
                            sortOrder = SortOrder.asc;
                          });
                          fetchTrips(reset: true);
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

            if (timeFilter != 'today') ...[
              StatusFilterDropdown(
                key: ValueKey('regular_$timeFilter'),
                currentFilter: statusFilter,
                onFilterSelected: setStatusFilter,
                onSearch: _handleSearch,
                enableSearch: true,
                statusFilters: [
                  {'label': 'All Status', 'value': null},
                  {'label': 'Draft', 'value': 'draft'},
                  {'label': 'Pending', 'value': 'pending'},
                  {'label': 'Canceled', 'value': 'canceled'},
                  {'label': 'Approved', 'value': 'approved'},
                  {'label': 'Rejected', 'value': 'rejected'},
                  {'label': 'Meter Read', 'value': 'read'},
                  {'label': 'Ongoing', 'value': 'ongoing'},
                  {'label': 'Finished', 'value': 'finished'},
                  {'label': 'Completed', 'value': 'completed'},
                ],
              ),
            ] else ...[
              StatusFilterDropdownCustomized(
                key: ValueKey('custom_$timeFilter'),
                currentFilter: statusFilter,
                onFilterSelected: setStatusFilter,
                onSearch: _handleSearch,
                enableSearch: true,
                statusFilters: [
                  {'label': 'Draft', 'value': 'draft'},
                  {'label': 'All', 'value': null},
                ],
              ),
            ],

            // Replace the CountBadge section with this:
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // CountBadge (using your existing widget)
                  CountBadge(totalCount: total, label: getDynamicBadgeLabel()),

                  const Spacer(),

                  // Sort Button
                  SortButton(
                    currentField: sortField,
                    currentOrder: sortOrder,
                    onSortChanged: (field, order) => setSort(field, order),
                    onToggleOrder: toggleSortOrder,
                  ),
                ],
              ),
            ),

            Expanded(
              child: TripListContent(
                scrollController: scrollController,
                trips: trips,
                isLoading: isLoading,
                loadingMore: loadingMore,
                errorMessage: errorMessage,
                hasMore: hasMore,
                onRetry: refreshTrips,
                emptyStateMessage: getEmptyStateMessage(),
                buildTripCard: (trip) => TripCard<TripCardModel>(
                  trip: trip,
                  onTap: () => _navigateToTripDetails(trip),
                  showVehicleInfo: true,
                  showLocationInfo: true,
                  showScheduleInfo: true,
                  showTripType: true,
                  showCreatedAt: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
