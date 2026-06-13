// lib/features/trips/widgets/status_filter_customized_dropdown.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';

class StatusFilterDropdownCustomized extends StatefulWidget {
  final String? currentFilter;
  final Function(String?) onFilterSelected;
  final List<Map<String, dynamic>> statusFilters;
  final Color activeColor;
  final Color inactiveColor;
  final Function(String)? onSearch;
  final bool enableSearch;
  final String? selectedDate;

  const StatusFilterDropdownCustomized({
    Key? key,
    this.currentFilter,
    required this.onFilterSelected,
    required this.statusFilters,
    this.activeColor = const Color(0xFFF9C80E),
    this.inactiveColor = Colors.black87,
    this.onSearch,
    this.enableSearch = false,
    this.selectedDate,
    
  }) : super(key: key);

  @override
  _StatusFilterDropdownCustomizedState createState() =>
      _StatusFilterDropdownCustomizedState();
}

class _StatusFilterDropdownCustomizedState
    extends State<StatusFilterDropdownCustomized> {
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Track text state for immediate clear icon response
  bool _hasText = false;

  // Consistent height for all components
  static const double _componentHeight = 40;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    // Update hasText immediately for instant UI response
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _toggleSearchMode() {
    if (!widget.enableSearch) return;

    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _hasText = false;
        if (widget.onSearch != null) {
          widget.onSearch!('');
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    if (!widget.enableSearch) return;

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (widget.onSearch != null) {
        widget.onSearch!(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  // Add resetSearchMode method
  void resetSearchMode() {
    if (_isSearchMode) {
      setState(() {
        _isSearchMode = false;
        _searchController.clear();
        _hasText = false;
        if (widget.onSearch != null) {
          widget.onSearch!('');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
      color: Colors.black,
      child: Row(
        children: [
          if (!_isSearchMode) ...[
            ...widget.statusFilters.map(
              (filter) => Expanded(
                child: _buildFilterButton(
                  //label: filter['label'] as String,
                  label:
                      filter['label'] == 'Select Date' && widget.selectedDate != null
                      ? _formatDateForDisplay(widget.selectedDate!)
                      : filter['label']!,
                  value: filter['value'] as String?,
                ),
              ),
            ),
          ] else ...[
            Expanded(flex: 3, child: _buildSearchField()),
          ],

          if (widget.enableSearch) ...[
            const SizedBox(width: 4),
            SizedBox(
              height: _componentHeight,
              width: _componentHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: _isSearchMode ? widget.activeColor : Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    _isSearchMode ? Icons.close : Icons.search,
                    color: _isSearchMode ? Colors.black : Colors.white,
                    size: 20,
                  ),
                  onPressed: _toggleSearchMode,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.expand(),
                  tooltip: _isSearchMode ? 'Close search' : 'Search trips',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateForDisplay(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildFilterButton({required String label, required String? value}) {
    final isSelected = widget.currentFilter == value;

    return GestureDetector(
      onTap: () => widget.onFilterSelected(value),
      child: Container(
        height: _componentHeight,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? widget.activeColor : Colors.grey[900],
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

  Widget _buildSearchField() {
    return Container(
      height: _componentHeight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[400], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by ID, Type, etc...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onSearchChanged,
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          if (_hasText)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
              onPressed: _clearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}
