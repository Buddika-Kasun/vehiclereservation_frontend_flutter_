// lib/features/trips/widgets/time_filter_row.dart
import 'package:flutter/material.dart';

class TimeFilterRow extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterSelected;
  final Color activeColor;
  final Color inactiveColor;

  const TimeFilterRow({
    Key? key,
    required this.currentFilter,
    required this.onFilterSelected,
    this.activeColor = const Color(0xFFF9C80E),
    this.inactiveColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'Today', 'value': 'today'},
      {'label': 'Week', 'value': 'week'},
      {'label': 'Month', 'value': 'month'},
      {'label': 'All', 'value': 'all'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final isSelected = currentFilter == filter['value'];
          return GestureDetector(
            onTap: () => onFilterSelected(filter['value'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: 70,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
