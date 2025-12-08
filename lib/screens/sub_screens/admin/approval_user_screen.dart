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
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String _searchQuery = '';
  String _errorMessage = '';
  bool _hasError = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApprovalUsers();
  }

  Future<void> _loadApprovalUsers() async {
  try {
    // Get users with approval role
    final response = await ApiService.getUsersByUserApproval();
    
    if (response['success'] == true) {
      final usersData = response['data']['users'] as List<dynamic>;
      setState(() {
        _approvalUsers = usersData.map((data) => {
          'id': data['_id']?.toString() ?? data['id']?.toString() ?? '', // Ensure string
          'displayName': data['displayname'] ?? 'Unknown User',
          'department': data['departmentName'] ?? 'No department',
          'role': data['role'] ?? 'User',
        }).toList();
        _isLoading = false;
      });
    } else {
      throw Exception(response['message'] ?? 'Failed to load approval users');
    }
  } catch (e) {
    print('Error loading approval users: $e');
    setState(() {
      _hasError = true;
      _errorMessage = e.toString();
      _isLoading = false;
    });
  }
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
          
          // Approval Users Section
          _buildApprovalUsersSection(),
        ],
      ),
    );
  }

}