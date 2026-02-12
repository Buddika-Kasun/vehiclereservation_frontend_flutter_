// lib/features/trips/assigned_(Drivers)/assigned_rides_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/assigned_(Drivers)/assigned_ride_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/ride_(Users)/ride_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/driver_trip_response.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/base/base_trip_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/time_filter_row.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/loading_overlay.dart';

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

      final response = await ApiService.getDriverAssignedTripsNew(request);

      final newTrips = response.data.trips;

      if (reset) {
        if (silent) {
          // Use the helper method for silent updates
          updateTripsSilently(newTrips, response.data.hasMore);
          if (mounted) {
            setState(() {
              errorMessage = '';
            });
          }
        } else {
          setState(() {
            trips = newTrips;
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
      print('Error loading assigned trips: $e');
      setState(() {
        errorMessage = 'Error loading assigned trips: ${e.toString()}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        isLoading: isLoading && trips.isEmpty,
        loadingMessage: 'Loading assigned trips...',
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
              currentFilter: statusFilter,
              onFilterSelected: setStatusFilter,
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
                emptyStateMessage: 'No assigned trips found',
                buildTripCard: (trip) => TripCard<TripCardModel>(
                  trip: trip,
                  onTap: () => _navigateToTripDetails(trip),
                  showVehicleInfo: true,
                  showLocationInfo: true,
                  showScheduleInfo: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
