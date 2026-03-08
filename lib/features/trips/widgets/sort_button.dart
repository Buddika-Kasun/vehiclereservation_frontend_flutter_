// lib/features/trips/widgets/sort_button.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/sort_enums.dart';

class SortButton extends StatelessWidget {
  final SortField currentField;
  final SortOrder currentOrder;
  final Function(SortField, SortOrder) onSortChanged;
  final VoidCallback onToggleOrder;

  const SortButton({
    Key? key,
    required this.currentField,
    required this.currentOrder,
    required this.onSortChanged,
    required this.onToggleOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        //border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sort field selector
          PopupMenuButton<SortField>(
            offset: const Offset(0, 40),
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            onSelected: (field) {
              onSortChanged(field, currentOrder);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortField.id,
                child: _buildSortOption(
                  'ID',
                  SortField.id.icon,
                  isSelected: currentField == SortField.id,
                ),
              ),
              PopupMenuItem(
                value: SortField.startTime,
                child: _buildSortOption(
                  'Time',
                  SortField.startTime.icon,
                  isSelected: currentField == SortField.startTime,
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: [
                  Icon(
                    currentField.icon,
                    color: const Color(0xFFF9C80E),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentField.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Separator
          Container(height: 20, width: 1, color: Colors.grey[800]),

          // Sort order toggle
          InkWell(
            onTap: onToggleOrder,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Row(
                children: [
                  Icon(
                    currentOrder == SortOrder.asc
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: const Color(0xFFF9C80E),
                    size: 16,
                  ),
                  /*
                  const SizedBox(width: 4),
                  Text(
                    currentOrder == SortOrder.asc ? 'Asc' : 'Desc',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  */
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    String label,
    IconData icon, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFF9C80E) : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFF9C80E) : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, color: Color(0xFFF9C80E), size: 16),
        ],
      ),
    );
  }
}
