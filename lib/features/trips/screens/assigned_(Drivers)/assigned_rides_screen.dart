// lib/features/trips/assigned_(Drivers)/assigned_rides_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/assigned_(Drivers)/assigned_ride_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/base/base_trip_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/sort_button.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/time_filter_row.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';

class AssignedRidesScreen extends StatefulWidget {
  final int userId;

  const AssignedRidesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AssignedRidesScreenState createState() => _AssignedRidesScreenState();
}

class _AssignedRidesScreenState extends BaseTripListState<AssignedRidesScreen> {
  @override
  String getScreenTitle() => 'Assigned Rides';

  @override
  String getScreenSubtitle() => 'Trips where you are the driver';

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

      final request = TripCardListRequest(
        timeFilter: timeFilter,
        statusFilter: statusFilter,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        sortField: sortField.name,
        sortOrder: sortOrder.name,
        page: page,
        limit: limit,
      );

      final response = await ApiService.getDriverAssignedTripsNew(request);

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

  void _navigateToTripDetails(TripCardModel trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailsScreen(tripId: trip.id),
      ),
    );

    if (result == true) {
      refreshTrips();
    }
  }

  void _handleSearch(String query) {
    setSearchQueryDebounced(query);
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
            ),
            StatusFilterDropdown(
              key: ValueKey('regular_$timeFilter'),
              currentFilter: statusFilter,
              onFilterSelected: setStatusFilter,
              onSearch: _handleSearch,
              enableSearch: true,
              statusFilters: [
                {'label': 'All Status', 'value': null},
                {'label': 'Pending', 'value': 'pending'},
                {'label': 'Approved', 'value': 'approved'},
                {'label': 'Meter Read', 'value': 'read'},
                {'label': 'Ongoing', 'value': 'ongoing'},
                {'label': 'Finished', 'value': 'finished'},
                {'label': 'Completed', 'value': 'completed'},
              ],
            ),
            
            // Replace the CountBadge section with this:
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // CountBadge (using your existing widget)
                  CountBadge(
                    totalCount: total,
                    label: '${getTripStatusLabel(statusFilter)} Trips',
                  ),

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
                  showScheduleInfo: false,
                  showTripType: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
