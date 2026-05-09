// lib/features/trips/all_trips_(Users)/all_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/base/base_trip_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/exceed_trips_(Sysadmin)/exceed_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/sort_button.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_customized_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';

class ExceedTripsScreen extends StatefulWidget {
  final UserRole userRole;

  const ExceedTripsScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _ExceedTripsScreenState createState() => _ExceedTripsScreenState();
}

class _ExceedTripsScreenState extends BaseTripListState<ExceedTripsScreen> {
  @override
  String getScreenTitle() => 'Exceed Trips';

  @override
  String getScreenSubtitle() => 'Browse all exceed trips and add or join';

  @override
  String getEmptyStateMessage() => 'No exceed trips found';

  @override
  String getLoadingMessage() => 'Loading trips...';

  @override
  String getErrorMessage() => 'Error loading trips';

  @override
  VoidCallback? getRefreshAction() => refreshTrips;

  @override
  void initState() {
    statusFilter = 'exceed';
    super.initState();
  }

  @override
  void setStatusFilter(String? status) {
    setState(() {
      statusFilter = status;
      page = 1;
      searchQuery = ''; // Clear search when changing filter
      total = null;
    });
    fetchTrips(reset: true);
  }

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
          if (!silent) {
            trips = [];
          }
        });
      } else {
        setState(() => loadingMore = true);
      }

      final request = TripCardListRequest(
        timeFilter: 'all',
        statusFilter: statusFilter,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        page: page,
        limit: limit,
        sortField: sortField.name, // 'id' or 'startTime'
        sortOrder: sortOrder.name, // 'asc' or 'desc'
      );

      final response = statusFilter == 'exceed'
          ? await ApiService.getAllTrips(request)
          : await ApiService.getAllExceedTrips(request);

      final newTrips = response.data.trips;
      final newTotal = response.data.total;

      if (reset) {
        if (silent) {
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

  void _handleSearch(String query) {
    setSearchQueryDebounced(query);
  }

  void _navigateToTripDetails(TripCardModel trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExceedTripDetailsScreen(userRole: widget.userRole, tripId: trip.id),
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
            StatusFilterDropdownCustomized(
              // KEY CHANGES WITH timeFilter - FORCES NEW WIDGET, NO API CALL
              //key: ValueKey('custom_$timeFilter'),
              currentFilter: statusFilter,
              onFilterSelected: setStatusFilter,
              onSearch: _handleSearch,
              enableSearch: true,
              statusFilters: [
                {'label': 'Exceed', 'value': 'exceed'},
                {'label': 'Accepted', 'value': 'accepted'},
              ],
            ),

            //if (searchQuery.isNotEmpty) buildSearchIndicator(),

            //CountBadge(totalCount: total, label: getDynamicBadgeLabel()),

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
                emptyStateMessage: getDynamicEmptyStateMessage(),
                buildTripCard: (trip) => TripCard<TripCardModel>(
                  trip: trip,
                  onTap: () => _navigateToTripDetails(trip),
                  showVehicleInfo: true,
                  showLocationInfo: true,
                  showScheduleInfo: true,
                  showTripType: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
