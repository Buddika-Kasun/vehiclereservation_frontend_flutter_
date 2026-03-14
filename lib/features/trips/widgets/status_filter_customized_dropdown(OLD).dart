// lib/features/trips/widgets/time_filter_row.dart
import 'package:flutter/material.dart';

class StatusFilterDropdownCustomizedSupervisor extends StatelessWidget {
  final String? currentFilter;
  final Function(String?) onFilterSelected;
  final List<Map<String, dynamic>> statusFilters;
  final Color activeColor;
  final Color inactiveColor;

  const StatusFilterDropdownCustomizedSupervisor.StatusFilterDropdownCustomized({
    Key? key,
    this.currentFilter,
    required this.onFilterSelected,
    required this.statusFilters,
    this.activeColor = const Color(0xFFF9C80E),
    this.inactiveColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      color: Colors.black,
      child: Row(
        children: [
          // Use Expanded to make buttons share available space equally
          ...statusFilters.map(
            (filter) => Expanded(
              child: _buildFilterButton(
                label: filter['label'] as String,
                value: filter['value'] as String?,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({required String label, required String? value}) {
    final isSelected = currentFilter == value;

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
