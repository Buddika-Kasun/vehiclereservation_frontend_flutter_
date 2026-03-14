import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';

class UserSearchDialog extends StatefulWidget {
  final String title;
  final Function(List<Map<String, dynamic>>) onUsersSelected;
  final int maxSelections;
  final int currentSelections;
  final List<Map<String, dynamic>>? excludedUserIds; // Users already in trip

  const UserSearchDialog({
    Key? key,
    required this.title,
    required this.onUsersSelected,
    required this.maxSelections,
    required this.currentSelections,
    this.excludedUserIds,
  }) : super(key: key);

  @override
  _UserSearchDialogState createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectedExpanded = true; // Control selected users expansion

  int get _remainingSeats => widget.maxSelections - _selectedUsers.length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await ApiService.searchUsers(query);
      if (response['success'] == true) {
        final usersData = response['data']['users'] as List<dynamic>;

        // Filter out users that are already in the trip or already selected
        final filteredUsers = usersData
            .where((data) {
              final userId = data['_id']?.toString() ?? data['id']?.toString();

              // Skip if user is already in trip
              if (widget.excludedUserIds != null &&
                  widget.excludedUserIds!.any(
                    (excluded) => excluded['id'].toString() == userId,
                  )) {
                return false;
              }

              // Skip if already selected in this dialog
              if (_selectedUsers.any(
                (selected) => selected['id'].toString() == userId,
              )) {
                return false;
              }

              return true;
            })
            .map(
              (data) => {
                'id': data['_id']?.toString() ?? data['id']?.toString() ?? '',
                'displayName':
                    data['displayName'] ?? data['displayname'] ?? 'Unknown',
                'contactNo': data['phone'] ?? data['contactNo'] ?? 'N/A',
                'email': data['email'] ?? '',
                'department':
                    data['department']?['name'] ?? data['department'] ?? 'N/A',
              },
            )
            .toList();

        setState(() {
          _searchResults = filteredUsers;
          _isSearching = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to search users');
      }
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _addUser(Map<String, dynamic> user) {
    if (_selectedUsers.length < widget.maxSelections) {
      setState(() {
        _selectedUsers.add(user);
        _searchResults.removeWhere((u) => u['id'] == user['id']);
        //_searchQuery = '';
        //_searchController.clear();
      });
    } else {
      _showMessage('Maximum seat limit reached', false);
    }
  }

  void _removeUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u['id'] == user['id']);
    });
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 750,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with seat info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingSeats > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_remainingSeats > 0 ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '$_remainingSeats/${widget.maxSelections} Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Selected users section - Expandable
            if (_selectedUsers.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    colorScheme: ColorScheme.dark(
                      primary: Colors.yellow,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_selectedUsers.length}',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Selected Passengers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    initiallyExpanded: _isSelectedExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isSelectedExpanded = expanded;
                      });
                    },
                    children: [
                      Container(
                        height: 180, // Fixed height for selected users list
                        padding: EdgeInsets.fromLTRB(4, 2, 4, 2),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return _buildCompactUserTile(user, 'remove');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Search field
            TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.yellow, fontSize: 15),
              enabled: _remainingSeats > 0,
              decoration: InputDecoration(
                labelText: _remainingSeats > 0
                    ? 'Search users by name or email'
                    : 'Maximum seats reached',
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: _remainingSeats > 0 ? Colors.grey : Colors.grey[600],
                ),
                floatingLabelStyle: TextStyle(
                  fontSize: 14,
                  color: _remainingSeats > 0 ? Colors.yellow : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 22,
                  color: _remainingSeats > 0 ? Colors.yellow : Colors.grey[600],
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _remainingSeats > 0
                        ? Colors.grey.shade600
                        : Colors.grey.shade800,
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _remainingSeats > 0
                        ? Colors.grey.shade600
                        : Colors.grey.shade800,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _remainingSeats > 0
                        ? Colors.yellow
                        : Colors.grey.shade800,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                if (_remainingSeats > 0) {
                  _searchUsers(query);
                }
              },
            ),
            SizedBox(height: 16),

            // Results header
            Row(
              children: [
                Text(
                  'Search Results',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (_searchResults.isNotEmpty)
                  Text(
                    '${_searchResults.length} found',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
              ],
            ),
            SizedBox(height: 8),

            // Results
            Expanded(
              child: _isSearching
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.yellow,
                        strokeWidth: 3,
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.search
                                : Icons.search_off,
                            color: Colors.grey[600],
                            size: 56,
                          ),
                          SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Start typing to search users'
                                : 'No users found',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return _buildCompactUserTile(user, 'add');
                      },
                    ),
            ),

            SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUsers.isEmpty
                          ? Colors.grey[700]
                          : Colors.yellow[600],
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _selectedUsers.isEmpty
                        ? null
                        : () {
                            widget.onUsersSelected(_selectedUsers);
                            Navigator.pop(context);
                          },
                    child: Text(
                      'Add ${_selectedUsers.length}',
                      style: TextStyle(
                        color: _selectedUsers.isEmpty
                            ? Colors.grey[500]
                            : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Compact user tile with reduced height
  Widget _buildCompactUserTile(Map<String, dynamic> user, String actionType) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: actionType == 'add'
              ? Colors.grey[800]!
              : Colors.yellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.yellow[600],
          child: Text(
            user['displayName'].isNotEmpty
                ? user['displayName'][0].toUpperCase()
                : 'U',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          user['displayName'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(Icons.phone, color: Colors.grey[400], size: 11),
            SizedBox(width: 3),
            Expanded(
              child: Text(
                user['contactNo'],
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user['department'] != null && user['department'] != 'N/A') ...[
              SizedBox(width: 8),
              Icon(Icons.business, color: Colors.grey[400], size: 11),
              SizedBox(width: 3),
              Expanded(
                child: Text(
                  user['department'].split(' ').first,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: actionType == 'add'
                ? Colors.blue.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              actionType == 'add' ? Icons.add : Icons.close,
              color: actionType == 'add' ? Colors.blue : Colors.red,
              size: 16,
            ),
            onPressed: () =>
                actionType == 'add' ? _addUser(user) : _removeUser(user),
            tooltip: actionType == 'add' ? 'Add user' : 'Remove user',
            padding: EdgeInsets.zero,
            iconSize: 16,
          ),
        ),
        onTap: () => actionType == 'add' ? _addUser(user) : _removeUser(user),
      ),
    );
  }
}
