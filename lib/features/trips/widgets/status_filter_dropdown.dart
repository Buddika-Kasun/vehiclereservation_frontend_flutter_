// lib/features/trips/widgets/status_filter_dropdown.dart
import 'package:flutter/material.dart';

class StatusFilterDropdown extends StatelessWidget {
  final String? currentFilter;
  final Function(String?) onFilterSelected;

  const StatusFilterDropdown({
    Key? key,
    required this.currentFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'label': 'All Status', 'value': null},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Approved', 'value': 'approved'},
      {'label': 'Ongoing', 'value': 'ongoing'},
      {'label': 'Completed', 'value': 'completed'},
      {'label': 'Canceled', 'value': 'canceled'},
      {'label': 'Rejected', 'value': 'rejected'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: currentFilter,
                  isExpanded: true,
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: statuses.map((status) {
                    return DropdownMenuItem<String?>(
                      value: status['value'] as String?,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            if (status['value'] != null) ...[
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getStatusColor(
                                    status['value'] as String,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              status['label'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onFilterSelected,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Filter by status',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.grey[700]!;
      case 'canceled':
        return Colors.red;
      case 'rejected':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

}
