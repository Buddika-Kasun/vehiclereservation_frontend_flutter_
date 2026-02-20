// lib/features/trips/reading_(Security)/meter_reading_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/base/base_trip_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/approval_(Approvers)/approval_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_customized_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/time_filter_row.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/status_filter_dropdown.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_list_content.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_security_card.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';

class RidesApprovalScreen extends StatefulWidget {
  //final int userId;

  const RidesApprovalScreen({Key? key,
    //required this.userId
  }) : super(key: key);

  @override
  _RidesApprovalScreenState createState() => _RidesApprovalScreenState();
}

class _RidesApprovalScreenState extends BaseTripListState<RidesApprovalScreen> {
  @override
  void initState() {
    statusFilter = 'needRead';
    super.initState();
  }

  @override
  String getScreenTitle() => 'Meter Readings';

  @override
  String getScreenSubtitle() => 'Trips where you are the security';

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

      final response = await ApiService.getTripsForMeterReadingNew(request);

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
      if (timeFilter == 'today') {
        statusFilter = 'needRead';
      } else {
        statusFilter = null;
      }
      page = 1;
    });
    fetchTrips(reset: true);
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
            if (timeFilter == 'today') ...[
              StatusFilterDropdownCustomizedSupervisor(
                currentFilter: statusFilter,
                onFilterSelected: setStatusFilter,
                statusFilters: [
                  {'label': 'Need Reading', 'value': 'needRead'},
                  {'label': 'Already Read', 'value': 'alreadyRead'},
                ],
              ),
            ]
            else ...[
              SizedBox(height: 6)
            ],
            CountBadge(
              totalCount: total,
              label: '${getTripStatusLabel(statusFilter)} Trips',
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
                buildTripCard: (trip) => TripSecurityCard<TripCardModel>(
                  trip: trip,
                  //onTap: () => (),
                  showVehicleInfo: true,
                  showLocationInfo: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}
