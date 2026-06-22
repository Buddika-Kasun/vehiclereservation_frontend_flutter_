// lib/features/users/screens/all_users_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/views_reports/all_users/user_details_screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

enum SortOrder { asc, desc }

class _AllUsersScreenState extends State<AllUsersScreen> {
  // Data
  List<dynamic> users = [];

  // Loading states
  bool isLoading = true;
  bool loadingMore = false;
  String errorMessage = '';

  // Pagination
  int page = 1;
  int limit = 20;
  int totalUsers = 0;
  bool hasMore = true;
  ScrollController scrollController = ScrollController();
  bool _isLoadingMore = false;

  // Filters
  int? selectedDepartmentId;
  String? selectedRole;
  String searchQuery = '';

  // Sort
  SortOrder currentOrder = SortOrder.asc;

  // Dropdown data
  List<Department> _departments = [];
  List<String> userRoles = [
    'System Admin',
    'Transport Supervisor',
    'Driver',
    'Security',
    'HR',
    'HOD',
    'Employee',
  ];

  // Search mode state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  static const double _componentHeight = 40;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    _searchController.addListener(_onTextChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
        page = 1;
        hasMore = true;
        isLoading = true;
      });
      _fetchUsers(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _scrollListener() {
    if (_isLoadingMore) return;

    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100) {
      if (hasMore && !loadingMore && !isLoading) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadInitialData() async {
    await _fetchDepartments();
    await _fetchUsers(reset: true);
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await ApiService.getDepartmentsForReg();
      if (response['success'] == true) {
        final List<dynamic> departments = response['data']['departments'] ?? [];
        setState(() {
          _departments = departments
              .map((data) => Department.fromJson(data))
              .toList();
          _departments.insert(0, Department(id: 0, name: 'All Departments', isActive: true));
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load cost centers');
      }
    } catch (e) {
      print('Error fetching departments: $e');
      setState(() {
        _departments = [Department(id: 0, name: 'All Departments', isActive: true)];
      });
    }
  }

  Future<void> _fetchUsers({required bool reset}) async {
    if (reset) {
      setState(() {
        page = 1;
        hasMore = true;
        isLoading = true;
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final response = await ApiService.getUsersByFiltration(
        page: page.toString(),
        limit: limit.toString(),
        departmentId:
            selectedDepartmentId != null &&
                selectedDepartmentId != 0
            ? selectedDepartmentId
            : null,
        role: selectedRole,
        sort: currentOrder == SortOrder.asc ? 'asc' : 'desc',
        search: searchQuery.isEmpty ? null : searchQuery,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> userData = response['data']['users'];
        final List<dynamic> newUsers = userData.map((json) {
          return {
            'id': json['id'],
            'displayname': json['displayname'],
            'role': json['role'],
            'department': json['departmentName'],
          };
        }).toList();
        final int total = response['data']['total'];
        final bool hasMoreRes = response['data']['hasMore'];

        setState(() {
          if (reset) {
            users = newUsers;
          } else {
            users.addAll(newUsers);
          }
          totalUsers = total;
          hasMore = hasMoreRes;
          isLoading = false;
          loadingMore = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading users: ${e.toString()}';
        isLoading = false;
        loadingMore = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (!hasMore || loadingMore || isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    setState(() {
      page++;
      loadingMore = true;
    });

    await _fetchUsers(reset: false);
    _isLoadingMore = false;
  }

  void _toggleSortOrder() {
    setState(() {
      currentOrder = currentOrder == SortOrder.asc
          ? SortOrder.desc
          : SortOrder.asc;
      _fetchUsers(reset: true);
    });
  }

  void _clearFilters() {
    setState(() {
      selectedDepartmentId = null;
      selectedRole = null;
      if (!_isSearchMode) {
        searchQuery = '';
      }
      currentOrder = SortOrder.asc;
      page = 1;
      hasMore = true;
      isLoading = true;
    });
    _fetchUsers(reset: true);
  }

  void _navigateToUserDetails(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailsScreen(userId: user['id'])),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'sysadmin':
        return 'System Admin';
      case 'supervisor':
        return 'Transport Supervisor';
      case 'admin':
        return 'HOD';
      case 'driver':
        return 'Driver';
      case 'security':
        return 'Security';
      case 'hr':
        return 'HR';
      case 'employee':
        return 'Employee';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'sysadmin':
        return const Color.fromARGB(255, 210, 28, 16);
      case 'supervisor':
        return const Color.fromARGB(255, 33, 150, 243);
      case 'security':
        return const Color.fromARGB(255, 76, 175, 80);
      case 'hr':
        return const Color.fromARGB(255, 156, 39, 176);
      case 'employee':
        return const Color.fromARGB(255, 255, 152, 0);
      case 'admin':
        return const Color.fromARGB(255, 63, 81, 181);
      case 'driver':
        return const Color.fromARGB(255, 244, 67, 54);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterSection(),
          _buildSortSection(),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : errorMessage.isNotEmpty
                ? _buildErrorState()
                : totalUsers == 0
                ? _buildEmptyState()
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      //color: Colors.green,
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'All Users',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (selectedDepartmentId != null ||
              selectedRole != null ||
              searchQuery.isNotEmpty)
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.clear, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      color: Colors.black,
      child: Column(
        children: [
          // Department Dropdown Row
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  height: _componentHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildDepartmentDropdown(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Role Dropdown Row
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  height: _componentHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildRoleDropdown(),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),
          // Search Row
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  height: _componentHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSearchField(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: selectedDepartmentId ?? 0,
        isExpanded: true,
        icon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(Icons.arrow_drop_down, color: Colors.white, size: 22),
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: _departments.map((Department dept) {
          return DropdownMenuItem<int>(
            value: dept.id,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Text(
                dept.name,
                style: TextStyle(
                  color: dept.id == 0 && selectedDepartmentId == null
                      ? Colors.grey[400]
                      : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: (int? newValue) {
          setState(() {
            selectedDepartmentId = newValue == 0
                ? null
                : newValue;
            page = 1;
            hasMore = true;
            isLoading = true;
          });
          _fetchUsers(reset: true);
        },
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Filter by department',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedRole,
        isExpanded: true,
        icon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(Icons.arrow_drop_down, color: Colors.white, size: 22),
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'All Roles',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          ...userRoles.map((String role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _getRoleDisplayName(role),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            );
          }),
        ],
        onChanged: (String? newValue) {
          setState(() {
            selectedRole = newValue;
            page = 1;
            hasMore = true;
            isLoading = true;
          });
          _fetchUsers(reset: true);
        },
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Filter by role',
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
              hintText: 'Search by name or email...',
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

  Widget _buildSortSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                'Count: ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  totalUsers.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Sort Button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              //border: Border.all(color: Colors.grey[800]!),
            ),
            child: InkWell(
              onTap: _toggleSortOrder,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: Row(
                  children: [
                    Icon(
                      currentOrder == SortOrder.asc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: const Color(0xFFF9C80E),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            itemCount: totalUsers + (loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == users.length && hasMore) {
                return _buildLoadingMoreIndicator();
              }

              // Safety check for index out of range
              if (index >= users.length) {
                return const SizedBox.shrink();
              }
              
              return _buildUserCard(users[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    return GestureDetector(
      onTap: () => _navigateToUserDetails(user),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getRoleColor(user['role']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  _getAvatarText(user['displayname']),
                  style: TextStyle(
                    color: _getRoleColor(user['role']),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['displayname'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    user['department'] ?? 'No Department',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user['role']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleDisplayName(user['role']),
                      style: TextStyle(
                        color: _getRoleColor(user['role']),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getAvatarText(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: const Color(0xFFF9C80E)),
          SizedBox(height: 16),
          Text('Loading users...', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFF9C80E),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _fetchUsers(reset: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C80E),
                foregroundColor: Colors.black,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, color: Colors.grey[600], size: 50),
                SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty
                      ? 'No users found matching "$searchQuery"'
                      : 'No users found',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                SizedBox(height: 8),
                if (searchQuery.isNotEmpty ||
                    selectedDepartmentId != null ||
                    selectedRole != null)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear filters',
                      style: TextStyle(color: const Color(0xFFF9C80E)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}