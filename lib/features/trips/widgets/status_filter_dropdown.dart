// lib/features/trips/widgets/status_filter_dropdown.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/utils/helper_methods.dart';

class StatusFilterDropdown extends StatefulWidget {
  final String? currentFilter;
  final List<Map<String, dynamic>> statusFilters;
  final Function(String?) onFilterSelected;
  final Function(String)? onSearch;
  final bool enableSearch;

  const StatusFilterDropdown({
    Key? key,
    required this.currentFilter,
    required this.statusFilters,
    required this.onFilterSelected,
    this.onSearch,
    this.enableSearch = false,
  }) : super(key: key);

  @override
  _StatusFilterDropdownState createState() => _StatusFilterDropdownState();
}

class _StatusFilterDropdownState extends State<StatusFilterDropdown> {
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Track text state for immediate clear icon response
  bool _hasText = false;

  // Calculate consistent height
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(
                16,
                0,
                widget.enableSearch ? 8 : 16,
                0,
              ),
              height: _componentHeight,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isSearchMode ? _buildSearchField() : _buildDropdown(),
            ),
          ),
          if (widget.enableSearch)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                height: _componentHeight,
                width: _componentHeight,
                decoration: BoxDecoration(
                  color: _isSearchMode ? Color(0xFFF9C80E) : Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: widget.currentFilter,
        isExpanded: true,
        icon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(Icons.arrow_drop_down, color: Colors.white, size: 22),
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: widget.statusFilters.map((status) {
          return DropdownMenuItem<String?>(
            value: status['value'] as String?,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  if (status['value'] != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: getStatusColor(status['value'] as String),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    status['label'] as String,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: widget.onFilterSelected,
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Filter by status',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
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
      ],
    );
  }
}
