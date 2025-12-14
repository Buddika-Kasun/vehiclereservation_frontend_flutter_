import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class ApprovalUsersScreen extends StatefulWidget {
  final VoidCallback? onBackToApprovalConfig;

  const ApprovalUsersScreen({Key? key, this.onBackToApprovalConfig}) : super(key: key);

  @override
  _ApprovalUsersScreenState createState() => _ApprovalUsersScreenState();
}

class _ApprovalUsersScreenState extends State<ApprovalUsersScreen> {
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _approvalUsers = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String _searchQuery = '';
  String _errorMessage = '';
  bool _hasError = false;
  Timer? _searchTimer;
  Timer? _autoRefreshTimer;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApprovalUsers();
    _loadPendingUsers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh data every 30 seconds
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadApprovalUsers();
        _loadPendingUsers();
      }
    });
  }

  Future<void> _loadApprovalUsers() async {
    try {
      final response = await ApiService.getUsersByUserApproval();

      if (response['success'] == true) {
        final usersData = response['data']['users'] as List<dynamic>;
        setState(() {
          _approvalUsers = usersData
              .map(
                (data) => {
                  'id': data['_id']?.toString() ?? data['id']?.toString() ?? '',
                  'displayName': data['displayname'] ?? 'Unknown User',
                  'department': data['departmentName'] ?? 'No department',
                  'role': data['role'] ?? 'User',
                  'isOnline':
                      data['isOnline'] ??
                      false, // Add online status if available
                },
              )
              .toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load approval users');
      }
    } catch (e) {
      print('Error loading approval users: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadPendingUsers() async {
    try {
      final response = await ApiService.getPendingUsers();

      if (response['success'] == true) {
        final usersData = response['data']['users'] as List<dynamic>;
        setState(() {
          _pendingUsers = usersData
              .map(
                (data) => {
                  'id': data['_id']?.toString() ?? data['id']?.toString() ?? '',
                  'displayName': data['displayname'] ?? 'Unknown User',
                  'email': data['email'] ?? '',
                  'phone': data['phone'] ?? '',
                  'role': data['role'] ?? 'User',
                  'department': data['departmentName'] ?? 'No department',
                  'registeredAt': data['createdAt'] ?? '',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      print('Error loading pending users: $e');
    }
  }

  // Override the mixin methods
  @override
  void _handleScreenRefresh(Map<String, dynamic> data) {
    final screen = data['screen'];
    final action = data['action'];
    final userId = data['userId'];

    if (screen == '/users/pending' || screen == '/admin/dashboard') {
      // Refresh the data
      _loadApprovalUsers();
      _loadPendingUsers();

      // Show visual feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 Refreshing user data...'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 2),
        ),
      );

      // If specific action provided, handle it
      if (action == 'add_user' && userId != null) {
        _highlightNewUser(userId);
      } else if (action == 'remove_user' && userId != null) {
        _removeUserFromList(userId);
      }
    }
  }

  @override
  void _handleUserRegisteredUpdate(Map<String, dynamic> data) {
    final userData = data['data'];

    // Add to pending users list with highlight
    setState(() {
      _pendingUsers.insert(0, {
        'id': userData['userId']?.toString() ?? '',
        'displayName': userData['username'] ?? 'New User',
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'role': userData['role'] ?? 'User',
        'department': userData['departmentId']?.toString() ?? '',
        'registeredAt': DateTime.now().toIso8601String(),
        'isNew': true, // Flag for highlighting
      });
    });

    // Show notification
    _showNewUserNotification(userData);
  }

  @override
  void _handleUserApprovedUpdate(Map<String, dynamic> data) {
    final userData = data['data'];
    final userId = userData['userId']?.toString();

    if (userId != null) {
      // Remove from pending users
      setState(() {
        _pendingUsers.removeWhere((user) => user['id'] == userId);
      });

      // Show approval notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ User ${userData['username']} has been approved'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _highlightNewUser(String userId) {
    // Find the user and mark as new
    final index = _pendingUsers.indexWhere((user) => user['id'] == userId);
    if (index != -1) {
      setState(() {
        _pendingUsers[index]['isNew'] = true;
        _pendingUsers[index]['highlightUntil'] = DateTime.now().add(
          Duration(seconds: 5),
        );
      });

      // Remove highlight after 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        if (mounted && index < _pendingUsers.length) {
          setState(() {
            _pendingUsers[index]['isNew'] = false;
          });
        }
      });
    }
  }

  void _removeUserFromList(String userId) {
    setState(() {
      _approvalUsers.removeWhere((user) => user['id'] == userId);
      _pendingUsers.removeWhere((user) => user['id'] == userId);
    });
  }

  void _showNewUserNotification(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.yellow[600]),
            SizedBox(width: 10),
            Text('New User Registered'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${userData['username']} has registered for an account.'),
            SizedBox(height: 10),
            Text('Email: ${userData['email']}'),
            Text('Phone: ${userData['phone']}'),
            Text('Role: ${userData['role']}'),
            SizedBox(height: 10),
            Text(
              'Please review and approve the user.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('DISMISS', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to pending users screen or show details
              _showUserDetails(userData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.yellow[600],
            ),
            child: Text('REVIEW NOW'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> userData) {
    // Implement user details view
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(),
            // Add user details here
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUsersSection() {
    if (_pendingUsers.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Approval (${_pendingUsers.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.yellow[600]),
                onPressed: _loadPendingUsers,
                tooltip: 'Refresh pending users',
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _pendingUsers.length,
            itemBuilder: (context, index) {
              final user = _pendingUsers[index];
              final isNew = user['isNew'] == true;

              return Container(
                width: 200,
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  color: isNew
                      ? Colors.yellow[50]
                      : Colors.white.withOpacity(0.9),
                  elevation: isNew ? 4 : 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isNew
                                  ? Colors.orange
                                  : Colors.blue,
                              child: Text(
                                user['displayName'][0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['displayName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    user['role'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isNew)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          user['email'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user['phone'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => _approveUser(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Approve',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _rejectUser(user),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Reject',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    try {
      final response = await ApiService.approveUser(user['id'], true);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${user['displayName']} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh lists
        _loadApprovalUsers();
        _loadPendingUsers();
      }
    } catch (e) {
      print('Error approving user: $e');
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    // Implement reject user functionality
  }

  Future<void> _searchUsers(String query) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    return;
  }

  // Cancel previous timer
  _searchTimer?.cancel();

  setState(() {
    _isSearching = true;
  });

  // Create new timer with delay
  _searchTimer = Timer(const Duration(milliseconds: 500), () async {
    try {
      final response = await ApiService.searchUsersApproval(query);
      if (response['success'] == true) {
        final usersData = response['data']['users'] as List<dynamic>;
        setState(() {
          _searchResults = usersData.map((data) => {
            'id': data['_id']?.toString() ?? data['id']?.toString() ?? '', // Ensure string
            'displayName': data['displayname'] ?? 'Unknown User',
            'department': data['departmentName'] ?? 'No department',
            'role': data['role'] ?? 'User',
          }).toList();
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
  });

}

  Future<void> _addUserAsApprovalUser(Map<String, dynamic> user) async {
  try {
    setState(() {
      _isSubmitting = true;
    });

    // Convert id to String to ensure it's the correct type
    final userId = user['id']?.toString() ?? '';
    
    // Call API to update user role to 'approval'
    final response = await ApiService.approveUser(userId, true);
    
    if (response['success'] == true) {
      // Add user to approval users list
      setState(() {
        _approvalUsers.add({
          ...user,
          'role': 'approval',
        });
      });

      // Remove from search results
      setState(() {
        _searchResults.removeWhere((u) => u['id'] == user['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['displayName']} added as approval user'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception(response['message'] ?? 'Failed to add user as approval user');
    }
  } catch (e) {
    print('Error adding approval user: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to add user: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}

  Future<void> _removeUserFromApproval(Map<String, dynamic> user) async {
  try {
    setState(() {
      _isSubmitting = true;
    });

    // Convert id to String to ensure it's the correct type
    final userId = user['id']?.toString() ?? '';

    // Call API to update user role to 'user' (default role)
    final response = await ApiService.approveUser(userId, false);
    
    if (response['success'] == true) {
      // Remove user from approval users list
      setState(() {
        _approvalUsers.removeWhere((u) => u['id'] == user['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['displayName']} removed from approval users'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      throw Exception(response['message'] ?? 'Failed to remove user from approval');
    }
  } catch (e) {
    print('Error removing approval user: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to remove user: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}
  
  Widget _buildUserCard(Map<String, dynamic> user, {bool isApprovalUser = false}) {
  // Safe way to get display name initial
  String getInitial() {
    final name = user['displayName']?.toString() ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  return Card(
    color: Colors.white.withOpacity(0.9),
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: isApprovalUser ? Colors.green : Colors.blue,
        child: Text(
          getInitial(),
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        user['displayName']?.toString() ?? 'Unknown User',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        '${user['department']?.toString() ?? 'No department'} • ${user['role']?.toString() ?? 'User'}',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: isApprovalUser
          ? IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: _isSubmitting ? null : () => _removeUserFromApproval(user),
              tooltip: 'Remove from approval users',
            )
          : IconButton(
              icon: Icon(Icons.add_circle, color: Colors.green),
              onPressed: _isSubmitting ? null : () => _addUserAsApprovalUser(user),
              tooltip: 'Add as approval user',
            ),
    ),
  );
}

  Widget _buildSearchSection() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Users',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.yellow),
                decoration: InputDecoration(
                  labelText: 'Search by name or email',
                  labelStyle: TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: Colors.yellow),
                  prefixIcon: Icon(Icons.search, color: Colors.yellow),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.yellow, width: 1),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                  _searchUsers(query);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Search Results - Make this section scrollable
        if (_isSearching)
          Center(
            child: CircularProgressIndicator(color: Colors.yellow[600]),
          )
        else if (_searchResults.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Results (${_searchResults.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              // Make search results scrollable with limited height
              Container(
                height: 200, // Fixed height for search results
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return _buildUserCard(user);
                  },
                ),
              ),
            ],
          )
        else if (_searchQuery.isNotEmpty)
          Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    ),
  );
}
  
  Widget _buildApprovalUsersSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Approval Users (${_approvalUsers.length})',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _approvalUsers.isEmpty
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Approval Users',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Search and add users as approval users',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _approvalUsers.length,
                    itemBuilder: (context, index) {
                      final user = _approvalUsers[index];
                      return _buildUserCard(user, isApprovalUser: true);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // Add a custom app bar method
  Widget _buildCustomAppBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBackToApprovalConfig ?? () => Navigator.pop(context),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Approval Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.yellow[600],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Error Loading Users',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadApprovalUsers,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // Custom App Bar with back button
          _buildCustomAppBar(),
          
          // Search Section
          _buildSearchSection(),
          
          //Divider(color: Colors.grey.shade600, height: 1),
          // Add pending users section here
          if (_pendingUsers.isNotEmpty) _buildPendingUsersSection(),
          
          // Approval Users Section
          _buildApprovalUsersSection(),
        ],
      ),
    );
  }

}