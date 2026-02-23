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
      padding: const EdgeInsets.fromLTRB( 12, 8, 12, 4), 
      color: Colors.black,
      child: Row(
        children: filters.map((filter) {
          return Expanded(
            child: _buildFilterButton(
              label: filter['label'] as String,
              value: filter['value'] as String,
              isSelected: currentFilter == filter['value'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onFilterSelected(value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
