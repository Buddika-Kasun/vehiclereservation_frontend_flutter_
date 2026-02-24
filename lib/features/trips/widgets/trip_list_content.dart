// lib/features/trips/widgets/trip_list_content.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';

class TripListContent extends StatelessWidget {
  final ScrollController? scrollController;
  final List<TripCardModel> trips;
  final bool isLoading;
  final bool loadingMore;
  final String errorMessage;
  final bool hasMore;
  final VoidCallback onRetry;
  final Widget Function(TripCardModel) buildTripCard;
  final String emptyStateMessage;
  final IconData emptyStateIcon;

  const TripListContent({
    Key? key,
    this.scrollController,
    required this.trips,
    required this.isLoading,
    required this.loadingMore,
    required this.errorMessage,
    required this.hasMore,
    required this.onRetry,
    required this.buildTripCard,
    this.emptyStateMessage = 'No trips found',
    this.emptyStateIcon = Icons.directions_car,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && trips.isEmpty) {
      return const SizedBox.shrink();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (trips.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: trips.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < trips.length) {
          return buildTripCard(trips[index]);
        } else {
          return _buildLoadMoreIndicator();
        }
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C80E),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(emptyStateIcon, size: 60, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            emptyStateMessage,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!loadingMore) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C80E)),
      ),
    );
  }

}
