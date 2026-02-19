// lib/features/trips/review_(Supervisor)/review_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/base/base_trip_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/review_(Supervisors)/review_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_customized_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/time_filter_row.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/creations/widgets/count_badge.dart';

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

      final request = TripCardListRequest(
        timeFilter: timeFilter,
        statusFilter: statusFilter,
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
    setState(() {
      timeFilter = filter;
      total = null;
      if (timeFilter == 'today'){
        statusFilter = 'draft';
      }
      else {
        statusFilter = null;
      }
      page = 1;
    });
    fetchTrips(reset: true);
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
            ),
            if (timeFilter != 'today') ...[
              StatusFilterDropdown(
                currentFilter: statusFilter,
                onFilterSelected: setStatusFilter,
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
              StatusFilterDropdownCustomizedSupervisor(
                currentFilter: statusFilter, 
                onFilterSelected: setStatusFilter,
                statusFilters: [
                  {'label': 'Draft', 'value': 'draft'},
                  {'label': 'All', 'value': null},
                ],
              )
            ],
            CountBadge(
              totalCount: total, 
              label: '${getTripStatusLabel(statusFilter)} Trips'
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
