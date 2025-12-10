import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_creation_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class UserCreationsScreen extends StatefulWidget {
  const UserCreationsScreen({Key? key}) : super(key: key);

  @override
  _UserCreationsScreenState createState() => _UserCreationsScreenState();
}

class _UserCreationsScreenState extends State<UserCreationsScreen> {
  //List<UserCreation> _userCreations = [];
  //List<UserCreation> _filteredUserCreations = [];
  List<UserCreation> _allUserCreations = [];
  List<UserCreation> _displayedUserCreations = [];

  List<Department> _availableDepartments = [];
  int? _expandedIndex;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'Pending'; // 'Pending', 'Approved', 'Rejected', 'All'
  int? _total;
  // Store temporary editable values ONLY for currently expanded item
  String? _tempSelectedRole;
  String? _tempSelectedDepartmentId;
  int? _tempEditingUserId;

  // Add pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadUserCreations();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreUserCreations();
    }
  }

  Future<void> _loadUserCreations({bool loadMore = false}) async {
    // Reset for new filter
    if (!loadMore) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _allUserCreations = [];
        _displayedUserCreations = [];
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await ApiService.getUserCreations(
        status: _selectedFilter == 'All' ? null : _selectedFilter,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (response['success'] == true) {
        final List<dynamic> userCreationsData = response['data']['users'] ?? [];
        final total = response['data']['total'] ?? 0;
        final currentPage = response['data']['page'] ?? _currentPage;
        final totalPages = response['data']['totalPages'] ?? 1;

        final newUserCreations = userCreationsData
            .map((data) => UserCreation.fromJson(data))
            .toList();

        setState(() {
          if (loadMore) {
            _allUserCreations.addAll(newUserCreations);
            _displayedUserCreations = List.from(_allUserCreations);
          } else {
            _allUserCreations = newUserCreations;
            _displayedUserCreations = newUserCreations;
          }

          _hasMoreData = currentPage < totalPages;
          _isLoading = false;
          _isLoadingMore = false;
          _total = total;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load user creations');
      }
    } catch (e) {
      print('Error loading user creations: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
        if (!loadMore) {
          _allUserCreations = [];
          _displayedUserCreations = [];
        }
      });
    }
  }

  Future<void> _loadMoreUserCreations() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _currentPage++;
    });

    await _loadUserCreations(loadMore: true);
  }

  void _applyFilter() {
    setState(() {
      _expandedIndex = -1;
      _clearTempValues();
    });

    // Load new data with filter
    _loadUserCreations();
  }

  Widget _buildLoadingMoreWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: _hasMoreData
            ? CircularProgressIndicator(color: AppColors.secondary)
            : Text(
                'No more users',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  // Clear temporary values when changing filter or collapsing
  void _clearTempValues() {
    _tempSelectedRole = null;
    _tempSelectedDepartmentId = null;
    _tempEditingUserId = null;
  }

  Future<void> _approveUserCreation(int userCreationId, int index, String role, String? departmentId) async {
    try {
      final response = await ApiService.approveUserCreationWithDetails(
        userCreationId,
        role: role,
        departmentId: departmentId,
      );
      
      if (response['success'] == true) {

        setState(() {
          _expandedIndex = -1;
          _selectedFilter = 'Approved';
        });

        await _loadUserCreations();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User approved successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to approve user');
      }
    } catch (e) {
      print('Error approving user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve user: $e')),
      );
      rethrow;
    }
  }

  Future<void> _rejectUserCreation(int userCreationId, int index) async {
    try {
      final response = await ApiService.rejectUserCreation(userCreationId);
      
      if (response['success'] == true) {
        setState(() {
          _expandedIndex = -1;
          _selectedFilter = 'Rejected';
        });

        await _loadUserCreations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User rejected successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to reject user');
      }
    } catch (e) {
      print('Error rejecting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject user: $e')),
      );
      rethrow;
    }
  }

  // Get available roles
  List<String> get _availableRoles => [
    'employee',
    'admin',
    'hr',
    'security',
    'driver',
  ];

  Future<void> _loadDepartments() async {
    try {
      final response = await ApiService.getDepartments();
      
      if (response['success'] == true) {
        final List<dynamic> departmentsData = response['data']['departments'] ?? [];
        setState(() {
          _availableDepartments = departmentsData.map((data) => Department.fromJson(data)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load departments');
      }
    } catch (e) {
      print('Error loading departments: $e');
      rethrow;
    }
  }

  // Check if approval is allowed
  bool _canApprove(String? departmentId) {
    return departmentId != null && departmentId.isNotEmpty;
  }

  // Get department name by ID
  String _getDepartmentName(String departmentId) {
    try {
      final department = _availableDepartments.firstWhere(
        (dept) => dept.id.toString() == departmentId,
        orElse: () => Department(
          id: 0, 
          name: 'Unknown', 
          isActive: true,
          employees: 0,
          headId: null,
          headName: null,
          costCenterId: null,
          costCenterName: null,
        ),
      );
      return department.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  // Get safe department ID - ensures the value exists in available departments
  String _getSafeDepartmentId(UserCreation userCreation) {
    if (_availableDepartments.isEmpty) return '';
    
    // First try to use the user's department if it exists
    if (userCreation.departmentId != null) {
      final userDeptId = userCreation.departmentId.toString();
      if (_availableDepartments.any((dept) => dept.id.toString() == userDeptId)) {
        return userDeptId;
      }
    }
    
    // Otherwise use the first available department
    return _availableDepartments.first.id.toString();
  }
  
  String _generateShortName(String displayName) {
    if (displayName.isEmpty) return 'U';
    final words = displayName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildErrorWidget()
              : _buildMainContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading User Creations...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserCreations,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Creations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Approve or reject user registration requests',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),

        // Filter Buttons
        _buildFilterButtons(),

        SizedBox(height: 8),
        
        // Available Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'User Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  //_filteredUserCreations.length.toString(),
                  //_displayedUserCreations.length.toString(),
                  _total.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // User Creations List
        Expanded(
                child: _displayedUserCreations.isEmpty 
            ? _buildEmptyState()
            : NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification &&
                      _scrollController.position.extentAfter == 0 &&
                      !_isLoadingMore &&
                      _hasMoreData) {
                    _loadMoreUserCreations();
                    return true;
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () => _loadUserCreations(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _displayedUserCreations.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _displayedUserCreations.length) {
                        return _buildLoadingMoreWidget();
                      }

                      //final userCreation = _filteredUserCreations[index];
                      final userCreation = _displayedUserCreations[index];
                      final isExpanded = _expandedIndex == index;
                      final shortName = _generateShortName(userCreation.displayname);
                      
                      // Get current values - use temp values ONLY if this is the currently expanded item
                      final bool isCurrentlyEditing = _tempEditingUserId == userCreation.id;
                      final currentRole = isCurrentlyEditing && _tempSelectedRole != null 
                          ? _tempSelectedRole! 
                          : userCreation.role.name;
                      final currentDepartmentId = isCurrentlyEditing && _tempSelectedDepartmentId != null
                          ? _tempSelectedDepartmentId!
                          : _getSafeDepartmentId(userCreation);
                      final canApprove = _canApprove(currentDepartmentId);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  // Collapsing - clear temp values
                                  _expandedIndex = null;
                                  _clearTempValues();
                                } else {
                                  // Expanding - set this as currently editing item
                                  _expandedIndex = index;
                                  _tempEditingUserId = userCreation.id;
                                  // Initialize temp values with original values
                                  _tempSelectedRole = userCreation.role.name;
                                  _tempSelectedDepartmentId = _getSafeDepartmentId(userCreation);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ColorGenerator.getRandomColor(userCreation.displayname).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: isExpanded 
                                    ? Border.all(color: ColorGenerator.getRandomColor(userCreation.displayname).withOpacity(0.2), width: 2)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      // User Icon
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: ColorGenerator.getRandomColor(userCreation.displayname),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            shortName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      
                                      // User Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userCreation.displayname,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              userCreation.email,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Status Badge
                                      _buildStatusBadge(userCreation.isApproved),
                                      
                                      // Expand/Collapse Arrow
                                      Transform.rotate(
                                        angle: isExpanded ? -1.5708 : 1.5708,
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Expanded Details
                                  if (isExpanded) ...[
                                    SizedBox(height: 16),
                                    Divider(height: 1, color: Colors.grey[300]),
                                    SizedBox(height: 16),
                                    
                                    // Contact Info
                                    _buildInfoRow(Icons.phone, userCreation.phone),
                                    _buildInfoRow(Icons.email, userCreation.email),
                                    
                                    SizedBox(height: 16),
                                    
                                    // Editable Role and Department (only for pending)
                                    if (userCreation.isApproved == 'pending') ...[
                                      // Role Dropdown
                                      _buildEditableDropdown(
                                        icon: Icons.person,
                                        label: 'User Role',
                                        value: currentRole,
                                        items: _availableRoles,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _tempSelectedRole = value;
                                            });
                                          }
                                        },
                                      ),
                                      
                                      SizedBox(height: 12),
                                      
                                      // Department Dropdown
                                      _buildDepartmentDropdown(
                                        currentDepartmentId: currentDepartmentId,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _tempSelectedDepartmentId = value;
                                            });
                                          }
                                        },
                                      ),
                                      
                                      // Warning message if department is not selected
                                      if (!canApprove) ...[
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.orange, size: 16),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Please select a department before approval',
                                                  style: TextStyle(
                                                    color: Colors.orange[800],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      
                                      SizedBox(height: 16),
                                    ] else ...[
                                      // Read-only role and department for approved/rejected
                                      Row(
                                        children: [
                                          _buildDetailItem(
                                            icon: Icons.person,
                                            title: 'Role',
                                            value: userCreation.role.displayName,
                                          ),
                                          SizedBox(width: 24),
                                          _buildDetailItem(
                                            icon: Icons.business,
                                            title: 'Department',
                                            value: userCreation.departmentName ?? 'Not Assigned',
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                    ],
                                    
                                    // Request Date
                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          icon: Icons.calendar_today,
                                          title: 'Requested',
                                          value: userCreation.createdAt?.toIso8601String().split('T').first ?? 'N/A',
                                        ),
                                      ],
                                    ),
                                          
                                    SizedBox(height: 16),
                                    
                                    // Action Buttons
                                    _buildActionButtons(userCreation, index, canApprove, currentRole, currentDepartmentId),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      )
      ]
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.black87,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case 'approved':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        statusText = 'Approved';
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        statusText = 'Rejected';
        break;
      default:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        statusText = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _isLoading ? 'Loading...' : 'No User Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter == 'Pending'
                ? 'There are no pending user requests'
                : 'No ${_selectedFilter.toLowerCase()} users',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserCreation userCreation, int index, bool canApprove, String currentRole, String currentDepartmentId) {
    final status = userCreation.isApproved;
    
    return Row(
      children: [
        // Reject Button (show for pending and approved)
        if (status == 'pending' || status == 'approved')
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.red,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showRejectConfirmation(index);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 8),
                      Text(
                        status == 'approved' ? 'Change to Reject' : 'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        if (status == 'pending' || status == 'approved') SizedBox(width: 12),
        
        // Approve Button (show for pending and rejected)
        if (status == 'pending' || status == 'rejected')
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: (status == 'pending' && canApprove) || status == 'rejected' 
                  ? Colors.green
                  : Colors.grey[400],
            borderRadius: BorderRadius.circular(12),
            boxShadow: (status == 'pending' && canApprove) || status == 'rejected' ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ] : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: (status == 'pending' && canApprove) || status == 'rejected' ? () {
                if (status == 'pending') {
                  _showApproveConfirmation(index, currentRole, currentDepartmentId);
                } else if (status == 'rejected') {
                  _showChangeToApproveConfirmation(index);
                }
              } : null,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8),
                    Text(
                      status == 'rejected' ? 'Change to Approve' : 'Approve',
                      style: TextStyle(
                        color: (status == 'pending' && canApprove) || status == 'rejected' 
                            ? Colors.white 
                            : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        )
      ],
    );
  }
  
  Widget _buildFilterButtons() {
    final filters = ['Pending', 'Approved', 'Rejected', 'All'];
    
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: _selectedFilter == filter,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                    _expandedIndex = -1;
                    _clearTempValues(); // Clear temp values when changing filter
                    _applyFilter();
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.secondary,
                labelStyle: TextStyle(
                  color: _selectedFilter == filter ? AppColors.primary : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown({
    required String currentDepartmentId,
    required Function(String?) onChanged,
  }) {
    // Ensure the current value exists in available departments
    String safeCurrentDepartmentId = currentDepartmentId;
    if (_availableDepartments.isNotEmpty && 
        !_availableDepartments.any((dept) => dept.id.toString() == currentDepartmentId)) {
      safeCurrentDepartmentId = _availableDepartments.first.id.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              'Department *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeCurrentDepartmentId,
              isExpanded: true,
              items: _availableDepartments.map((department) {
                return DropdownMenuItem(
                  value: department.id.toString(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      department.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showRejectConfirmation(int index) {
    bool _isSubmitting = false;
    //final userCreation = _filteredUserCreations[index];
    final userCreation = _displayedUserCreations[index];
    final currentStatus = userCreation.isApproved;
    final actionText = 'Reject';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    currentStatus == 'approved'
                        ? 'Are you sure you want to change ${userCreation.displayname} from Approved to Rejected?'
                        : 'Are you sure you want to reject ${userCreation.displayname}?',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () => Navigator.pop(context),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () async {
                                try {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  await _rejectUserCreation(userCreation.id, index);
                                  Navigator.pop(context);
                                } catch (e) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        actionText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
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
        },
      ),
    );
  }

  void _showApproveConfirmation(int index, String role, String departmentId) {
    bool _isSubmitting = false;
    //final userCreation = _filteredUserCreations[index];
    final userCreation = _displayedUserCreations[index];
    final departmentName = _getDepartmentName(departmentId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Approve User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Are you sure you want to approve ${userCreation.displayname}?',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Show selected role and department
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role: ${role.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Department: $departmentName',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () => Navigator.pop(context),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () async {
                                try {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  await _approveUserCreation(
                                    userCreation.id, 
                                    index, 
                                    role, 
                                    departmentId
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Text(
                                        'Approve',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
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
        },
      ),
    );
  }
  
  void _showChangeToApproveConfirmation(int index) {
    bool _isSubmitting = false;
    //final userCreation = _filteredUserCreations[index];
    final userCreation = _displayedUserCreations[index];
    
    // Use temporary values if available, otherwise use original values
    _tempSelectedRole = _tempSelectedRole ?? userCreation.role.name;
    _tempSelectedDepartmentId = _tempSelectedDepartmentId ?? _getSafeDepartmentId(userCreation);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final canApprove = _canApprove(_tempSelectedDepartmentId);

          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'Change to Approve',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Change ${userCreation.displayname} from Rejected to Approved?',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Role Dropdown
                  _buildRoleDropdownNew(
                    currentRole: _tempSelectedRole ?? '',
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _tempSelectedRole = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Department Dropdown
                  _buildDepartmentDropdownNew(
                    currentDepartmentId: _tempSelectedDepartmentId ?? '',
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _tempSelectedDepartmentId = value;
                        });
                      }
                    },
                  ),
                  
                  // Warning message if department is not selected
                  if (!canApprove) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please select a department before approval',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () {
                                Navigator.pop(context);
                              },
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Approve Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting || !canApprove 
                                ? Colors.grey 
                                : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: (_isSubmitting || !canApprove) ? [] : [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: (_isSubmitting || !canApprove) ? null : () async {
                                try {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  await _approveUserCreation(
                                    userCreation.id, 
                                    index, 
                                    _tempSelectedRole ?? '', 
                                    _tempSelectedDepartmentId
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        'Approve',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
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
        },
      ),
    );
  }
  
  Widget _buildDepartmentDropdownNew({
    required String currentDepartmentId,
    required Function(String?) onChanged,
  }) {
    // Ensure the current value exists in available departments
    String safeCurrentDepartmentId = currentDepartmentId;
    if (_availableDepartments.isNotEmpty && 
        !_availableDepartments.any((dept) => dept.id.toString() == currentDepartmentId)) {
      safeCurrentDepartmentId = _availableDepartments.first.id.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with Icon
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Department *',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Dropdown without icon
        DropdownButtonFormField<String>(
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.yellow),
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: Colors.grey),
            floatingLabelStyle: const TextStyle(color: Colors.yellow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellow, width: 1),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: safeCurrentDepartmentId,
          items: _availableDepartments.map((department) {
            return DropdownMenuItem(
              value: department.id.toString(),
              child: Text(department.name, style: TextStyle(color: Colors.yellow)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  Widget _buildRoleDropdownNew({
    required String currentRole,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with Icon
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'User Role',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Dropdown without icon
        DropdownButtonFormField<String>(
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.yellow),
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: Colors.grey),
            floatingLabelStyle: const TextStyle(color: Colors.yellow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellow, width: 1),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: currentRole,
          items: _availableRoles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase(), style: TextStyle(color: Colors.yellow)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

}