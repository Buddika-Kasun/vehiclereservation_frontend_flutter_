import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/constant.dart';

class TimeFilters extends StatefulWidget {
  final Function(String) onFilterChanged;

  const TimeFilters({Key? key, required this.onFilterChanged}) : super(key: key);

  @override
  _TimeFiltersState createState() => _TimeFiltersState();
}

class _TimeFiltersState extends State<TimeFilters> {
  String _selectedFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.timeFilters.length,
        itemBuilder: (context, index) {
          final filter = AppConstants.timeFilters[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
              widget.onFilterChanged(filter);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _selectedFilter == filter ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: _selectedFilter == filter ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
