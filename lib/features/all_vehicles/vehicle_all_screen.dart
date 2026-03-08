// lib/features/vehicles/screens/vehicles_all_screen.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/vehicle_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/all_vehicles/base/base_all_vehicles_list_state.dart';
import 'package:vehiclereservation_frontend_flutter_/features/all_vehicles/widget/vehicle_card.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/creations/widgets/status_filter_buttons.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/trip_header.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/loading_overlay.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/count_badge.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/list_content.dart';

class VehicleAllScreen extends StatefulWidget {
  final User user;
  final bool? all;

  const VehicleAllScreen({Key? key, required this.user, this.all})
    : super(key: key);

  @override
  _VehiclesAllScreenState createState() => _VehiclesAllScreenState();
}

class _VehiclesAllScreenState
    extends BaseAllVehiclesListState<VehicleAllScreen> {
  // Filter types for vehicles
  String selectedFilter =
      'All'; // 'All', 'Primary', 'Secondary', 'Active', 'Inactive'

  // Separate lists for primary and secondary vehicles
  List<Vehicle> primaryVehicles = [];
  List<Vehicle> secondaryVehicles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  String getScreenTitle() {
    return (widget.user.role == UserRole.sysadmin ||
            (widget.all != null && widget.all == true))
        ? 'All Vehicles'
        : 'My Vehicles';
  }

  @override
  String getScreenSubtitle() {
    return (widget.user.role == UserRole.sysadmin ||
            (widget.all != null && widget.all == true))
        ? 'All vehicles in the system'
        : 'Vehicles assigned to you';
  }

  @override
  String getEmptyStateMessage() {
    if (selectedFilter == 'Primary') {
      return 'No primary vehicles';
    } else if (selectedFilter == 'Secondary') {
      return 'No secondary vehicles';
    }
    return 'No vehicles found';
  }

  @override
  String getLoadingMessage() => 'Loading vehicles...';

  @override
  String getErrorMessage() => 'Error loading vehicles';

  @override
  VoidCallback? getRefreshAction() => refreshAllVehicles;

  // Override setFilter to handle vehicle-specific filters
  @override
  void setFilter(String filter) {
      setState(() {
        displayedAllVehicles = [];
        selectedFilter = filter;
        currentPage = 1;
        expandedIndex = null;
        isLoading = true; // Use existing loading state
      });

      // Apply filter to displayed vehicles with delay
      _applyFilter();
  }

  void _applyFilter() async {
    // Add a small delay to show loading state (500ms)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      if (selectedFilter == 'All') {
        displayedAllVehicles = List.from(allVehicles);
      } else if (selectedFilter == 'Primary') {
        displayedAllVehicles = allVehicles
            .where((v) => primaryVehicles.contains(v))
            .toList();
      } else if (selectedFilter == 'Secondary') {
        displayedAllVehicles = allVehicles
            .where((v) => secondaryVehicles.contains(v))
            .toList();
      }

      isLoading = false; // Hide loading indicator
    });
  }

  List<Vehicle> _safeMapToVehicles(List<dynamic> data) {
    try {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return Vehicle.fromJson(item);
        } else if (item is Vehicle) {
          return item;
        } else {
          print('Unexpected vehicle data type: ${item.runtimeType}');
          return Vehicle(
            id: 0,
            regNo: 'Unknown',
            model: 'Unknown Model',
            isActive: false,
            seatingCapacity: 0,
            odometerLastReading: 0.0,
          );
        }
      }).toList();
    } catch (e) {
      print('Error mapping vehicle data: $e');
      return [];
    }
  }

  @override
  Future<void> fetchAllVehicles({
    required bool reset,
    bool silent = false,
  }) async {
    try {
      if (reset) {
        setState(() {
          if (!silent) {
            isLoading = true;
          }
          currentPage = 1;
          hasMoreData = true;
          if (!silent) {
            allVehicles = [];
            displayedAllVehicles = [];
            primaryVehicles = [];
            secondaryVehicles = [];
          }
        });
      } else {
        setState(() => loadingMore = false);
      }

      final driverId = (widget.all != null && widget.all == true)
          ? -1
          : widget.user.id;
      final response = await ApiService.getDriverVehicles(driverId);

      if (response['success'] == true) {
        final primaryData = response['data']['primaryVehicles'] ?? [];
        final secondaryData = response['data']['secondaryVehicles'] ?? [];

        final primaryVehiclesList = _safeMapToVehicles(primaryData);
        final secondaryVehiclesList = _safeMapToVehicles(secondaryData);

        // Combine both lists
        final allVehiclesList = [
          ...primaryVehiclesList,
          ...secondaryVehiclesList,
        ];
        final totalCount = allVehiclesList.length;

        if (reset) {
          if (silent) {
            updateAllVehiclesSilently(allVehiclesList, totalCount, false);
            if (mounted) {
              setState(() {
                errorMessage = '';
              });
            }
          } else {
            setState(() {
              allVehicles = allVehiclesList;
              primaryVehicles = primaryVehiclesList;
              secondaryVehicles = secondaryVehiclesList;
              total = totalCount;
              hasMoreData = false; // No pagination for vehicles
              //isLoading = false;
              errorMessage = '';
            });

            // Apply current filter
            _applyFilter();
          }
        } else {
          setState(() {
            // Not used for vehicles since no pagination
            loadingMore = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load vehicles');
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

  Future<void> _refreshAfterChecklist(bool? result) async {
    if (result == true) {
      MessageOverlay.showSuccess(
        context: context,
        message: "Checklist completed successfully!",
        duration: const Duration(seconds: 2),
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
      );
      await Future.delayed(const Duration(seconds: 1));
      await fetchAllVehicles(reset: true);
    }
  }

  // Create status filters for vehicles
  List<Map<String, dynamic>> get _statusFilters => [
    {'label': 'All', 'value': 'All'},
    {'label': 'Primary', 'value': 'Primary'},
    {'label': 'Secondary', 'value': 'Secondary'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        isLoading: isLoading && displayedAllVehicles.isEmpty,
        loadingMessage: getLoadingMessage(),
        child: Column(
          children: [
            TripHeader(
              title: getScreenTitle(),
              subtitle: getScreenSubtitle(),
              onRefresh: getRefreshAction(),
            ),
            StatusFilterButtons(
              currentFilter: selectedFilter,
              onFilterSelected: (value) => setFilter(value ?? 'All'),
              statusFilters: _statusFilters,
            ),

            // Replace the CountBadge section with this:
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // CountBadge (using your existing widget)
                  CountBadge(
                    totalCount: displayedAllVehicles.length,
                    label: 'Vehicles',
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListContent<Vehicle>(
                scrollController: scrollController,
                items: displayedAllVehicles,
                isLoading: isLoading,
                loadingMore: loadingMore,
                errorMessage: errorMessage,
                hasMore: hasMoreData,
                onRetry: refreshAllVehicles,
                emptyStateMessage: getEmptyStateMessage(),
                emptyStateIcon: Icons.directions_car,
                buildItem: (vehicle) {
                  final index = displayedAllVehicles.indexOf(vehicle);

                  // Determine assignment type
                  final String assignmentType =
                      primaryVehicles.contains(vehicle)
                      ? 'primary'
                      : 'secondary';

                  return VehicleCard(
                    vehicle: vehicle,
                    isExpanded: expandedIndex == index,
                    onTap: () => toggleExpand(index),
                    user: widget.user,
                    assignmentType: assignmentType,
                    onChecklistComplete: () => _refreshAfterChecklist(true),
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
