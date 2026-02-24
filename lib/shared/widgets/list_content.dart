// lib/features/common/widgets/list_content.dart
import 'package:flutter/material.dart';

class ListContent<T> extends StatelessWidget {
  final ScrollController? scrollController;
  final List<T> items;
  final bool isLoading;
  final bool loadingMore;
  final String errorMessage;
  final bool hasMore;
  final VoidCallback onRetry;
  final Widget Function(T) buildItem;
  final String emptyStateMessage;
  final IconData emptyStateIcon;

  const ListContent({
    Key? key,
    this.scrollController,
    required this.items,
    required this.isLoading,
    required this.loadingMore,
    required this.errorMessage,
    required this.hasMore,
    required this.onRetry,
    required this.buildItem,
    this.emptyStateMessage = 'No items found',
    this.emptyStateIcon = Icons.info_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < items.length) {
          return buildItem(items[index]);
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
              style: const TextStyle(color: Colors.grey),
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
