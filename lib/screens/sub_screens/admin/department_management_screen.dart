import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/costCenter_model.dart';
import 'package:vehiclereservation_frontend_flutter_/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class DepartmentsManagementScreen extends StatefulWidget {
  const DepartmentsManagementScreen({Key? key}) : super(key: key);

  @override
  _DepartmentsManagementScreenState createState() => _DepartmentsManagementScreenState();
}

class _DepartmentsManagementScreenState extends State<DepartmentsManagementScreen> {
  List<Department> _departments = [];
  //List<User> _users = [];
  List<ShortUser> _departmentUsers = [];
  List<CostCenter> _costCenters = [];
  int? _expandedIndex;
  bool _isLoading = true;
  bool _hasCompany = false;
  bool _hasCostCenter = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCompanyAndLoadData();
  }

  Future<void> _checkCompanyAndLoadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // First check if company exists
      final companyResponse = await ApiService.getCompanyStatus();
      
      if (companyResponse['success'] == true) {
        setState(() {
          _hasCompany = companyResponse['data'] ?? false;
        });

        final costCenterResponse = await ApiService.getCostCenterStatus();

        if (costCenterResponse['success'] == true) {
          setState(() {
            _hasCostCenter = costCenterResponse['data'] ?? false;
          });

          if (_hasCompany && _hasCostCenter) {
            // Load all data only if company exists
            await Future.wait([
              _loadDepartments(),
              //_loadUsers(),
              _loadCostCenters(),
            ]);
            setState(() {
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          throw Exception(costCenterResponse['message'] ?? 'Failed to check cost center status');
        }
      } else {
        throw Exception(companyResponse['message'] ?? 'Failed to check company status');
      }
    } catch (e) {
      print('Error checking company: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await ApiService.getDepartments();
      
      if (response['success'] == true) {
        final List<dynamic> departmentsData = response['data']['departments'] ?? [];
        setState(() {
          _departments = departmentsData.map((data) => Department.fromJson(data)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load departments');
      }
    } catch (e) {
      print('Error loading departments: $e');
      rethrow;
    }
  }

  /*
  Future<void> _loadUsers() async {
    try {
      final response = await ApiService.getUsers();
      
      if (response['success'] == true) {
        final List<dynamic> usersData = response['data']['users'] ?? [];
        setState(() {
          _users = usersData.map((data) => User.fromJson(data)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      print('Error loading users: $e');
      rethrow;
    }
  }

  */
  Future<void> _loadUsersByDepartment(int departmentId) async {
    try {
      final response = await ApiService.getUsersByDepartment(departmentId);
      //final response = await ApiService.getUsers();
      
      if (response['success'] == true) {
        final List<dynamic> usersData = response['data']['users'] ?? [];
        setState(() {
          _departmentUsers = usersData.map((data) => ShortUser.fromJson(data)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load department users');
      }
    } catch (e) {
      print('Error loading department users: $e');
      rethrow;
    }
  }

  Future<void> _loadCostCenters() async {
    try {
      final response = await ApiService.getCostCenters();
      
      if (response['success'] == true) {
        final List<dynamic> costCentersData = response['data']['costCenters'] ?? [];
        setState(() {
          _costCenters = costCentersData.map((data) => CostCenter.fromJson(data)).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load cost centers');
      }
    } catch (e) {
      print('Error loading cost centers: $e');
      rethrow;
    }
  }

  Future<void> _createDepartment(Department department) async {
    try {
      final response = await ApiService.createDepartment(department.toJson());
      
      if (response['success'] == true) {
        await _loadDepartments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department created successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create department');
      }
    } catch (e) {
      print('Error creating department: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create department: $e')),
      );
      rethrow;
    }
  }

  Future<void> _updateDepartment(Department department) async {
    try {
      final response = await ApiService.updateDepartment(department.id, department.toJson());
      
      if (response['success'] == true) {
        await _loadDepartments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department updated successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update department');
      }
    } catch (e) {
      print('Error updating department: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update department: $e')),
      );
      rethrow;
    }
  }

  Future<void> _deleteDepartment(int id, int index) async {
    try {
      final response = await ApiService.deleteDepartment(id);
      
      if (response['success'] == true) {
        setState(() {
          _departments.removeAt(index);
          _expandedIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department deleted successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete department');
      }
    } catch (e) {
      print('Error deleting department: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete department: $e')),
      );
      rethrow;
    }
  }

  String _generateShortName(String fullName) {
    if (fullName.isEmpty) return 'DP';
    final words = fullName.split(' ');
    final initials = words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildErrorWidget()
              : !_hasCompany
                  ? _buildNoCompanyWidget()
                  : _buildMainContent(),
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
                  'Departments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Create New Button
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showCreateDepartmentDialog();
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Create New',
                          style: TextStyle(
                            color: AppColors.primary,
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

          SizedBox(height: 8),
          
          // Available Section Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Available',
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
                    _departments.length.toString(),
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

          // Departments List
          Expanded(
            child: _departments.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final department = _departments[index];
                final isExpanded = _expandedIndex == index;
                final shortName = _generateShortName(department.name);
                
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
                          _expandedIndex = isExpanded ? null : index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorGenerator.getRandomColor(department.name).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: isExpanded 
                              ? Border.all(color: ColorGenerator.getRandomColor(department.name).withOpacity(0.2), width: 2)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                // Department Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: ColorGenerator.getRandomColor(department.name),
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
                                
                                // Department Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shortName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        department.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
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
                              
                              // Details Grid
                              Row(
                                children: [
                                  _buildDetailItem(
                                    icon: Icons.people,
                                    title: 'Employees',
                                    value: '${department.employees}',
                                  ),
                                  SizedBox(width: 24),
                                  _buildDetailItem(
                                    icon: Icons.person,
                                    title: 'HOD',
                                    value: department.headName ?? '',
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  _buildDetailItem(
                                    icon: Icons.account_balance_wallet,
                                    title: 'Cost Center',
                                    value: department.costCenterName ?? '',
                                  ),
                                  SizedBox(width: 24),
                                  _buildDetailItem(
                                    icon: Icons.circle,
                                    title: 'Status',
                                    value: department.isActive ? 'Active' : 'Inactive',
                                    valueColor: department.isActive ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  // Edit Button
                                  Expanded(
                                    child: Container(
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.secondary.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            _showEditDepartmentDialog(index, department);
                                          },
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Edit Department',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
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
                                  SizedBox(width: 12),
                                  
                                  // Delete Button
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          _showDeleteConfirmation(index);
                                        },
                                        child: Center(
                                          child: Icon(Icons.delete, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
        ],
      );    
  }

  void _showEditDepartmentDialog(int index, Department department) async {
    String fullName = department.name;
    bool isActive = department.isActive;
    bool _isSubmitting = false;
    bool _loadingUsers = true;

    // Load department-specific users
    await _loadUsersByDepartment(department.id);

    setState(() {
      _loadingUsers = false;
    });

    // Fix: Ensure values exist in dropdown items or set to null
    String? selectedHead = _getValidHeadValue(department.headId, _departmentUsers);
    String? selectedCostCenter = _getValidCostCenterValue(department.costCenterId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
                      'Edit Department',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Full Name Field
                  TextField(
                    controller: TextEditingController(text: fullName),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.business, color: Colors.yellow),
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
                    ),
                    onChanged: (value) => fullName = value,
                  ),
                  const SizedBox(height: 16),

                  // Head of Department Dropdown
                  _loadingUsers
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.yellow,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Loading department users...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.yellow),
                          decoration: InputDecoration(
                            labelText: 'Head of Department',
                            labelStyle: const TextStyle(color: Colors.grey),
                            floatingLabelStyle: const TextStyle(color: Colors.yellow),
                            prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.yellow, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          value: selectedHead,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None', style: TextStyle(color: Colors.grey)),
                            ),
                            ..._departmentUsers.map((user) {
                              return DropdownMenuItem(
                                value: user.id.toString(),
                                child: Text(
                                  user.displayname, 
                                  style: const TextStyle(color: Colors.yellow),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedHead = value;
                            });
                          },
                        ),
              
                  const SizedBox(height: 16),

                  // Cost Center Dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Cost Center',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.yellow),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: selectedCostCenter,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None', style: TextStyle(color: Colors.grey)),
                      ),
                      ..._costCenters.map((center) {
                        return DropdownMenuItem(
                          value: center.id.toString(),
                          child: Text(center.name, style: const TextStyle(color: Colors.yellow)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCostCenter = value;
                      });
                    },
                  ),
              
                  const SizedBox(height: 8),

                  // Department Users Info
                  if (_departmentUsers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '${_departmentUsers.length} users available in this department',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_departmentUsers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded( // Add this
                            child: Text(
                              'No users registered in this department yet',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Active Department",
                          style: TextStyle(color: Colors.white, fontSize: 16)
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            onChanged: (bool value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                            inactiveTrackColor: Colors.transparent,
                            inactiveThumbColor: Colors.yellow.shade600,
                            activeColor: Colors.yellow[600],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                  const SizedBox(height: 24),

                  // Buttons Row
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
                      
                      // Save Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
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
                              onTap: _isSubmitting ? null : () async {
                                try {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  final updatedDepartment = Department(
                                    id: _departments[index].id,
                                    name: fullName,
                                    employees: department.employees,
                                    headId: selectedHead, // Can be null
                                    costCenterId: selectedCostCenter, // Can be null
                                    isActive: isActive,
                                  );

                                  await _updateDepartment(updatedDepartment);
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
                                        'Save',
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

  // Helper methods to validate dropdown values
  String? _getValidHeadValue(String? headId, List<ShortUser> userList) {
  if (headId == null || headId.isEmpty) return null;
  
  // Check if the headId exists in the provided user list
  final userExists = userList.any((user) => user.id.toString() == headId);
  return userExists ? headId : null;
}

  String? _getValidCostCenterValue(String? costCenterId) {
  if (costCenterId == null || costCenterId.isEmpty) return null;
  
  // Check if the costCenterId exists in _costCenters list
  final costCenterExists = _costCenters.any((center) => center.id.toString() == costCenterId);
  return costCenterExists ? costCenterId : null;
}

  void _showDeleteConfirmation(int index) {
  bool _isSubmitting = false;

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
                const Center(
                  child: Text(
                    'Delete Department',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Text(
                  'Are you sure you want to delete ${_departments[index].name} department?',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Buttons Row
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
                    
                    // Delete Button
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

                                await _deleteDepartment(_departments[index].id, index);
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
                                      'Delete',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Department Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your department to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
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

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading...',
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
              onPressed: _checkCompanyAndLoadData,
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

  Widget _buildNoCompanyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Company Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _hasCompany ? 
                _hasCostCenter ?
                 ''
                 :
                 'You need to create a cost center before managing departments.'
                : 
                'You need to create a company and cost centers before managing departments.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            /*ElevatedButton.icon(
              onPressed: () {
                // Navigate to company creation screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateCompanyScreen()));
              },
              icon: Icon(Icons.add_business),
              label: Text('Create Company'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  void _showCreateDepartmentDialog() {
    String fullName = '';
    String? selectedHead;
    String? selectedCostCenter;
    bool isActive = true;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
                      'New Department',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Full Name Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.business, color: Colors.yellow),
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
                      hintText: 'e.g., Human Resources',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => fullName = value,
                  ),
                  const SizedBox(height: 16),

                  // Head of Department Dropdown
                  /*DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Head of Department',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.person, color: Colors.yellow),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: selectedHead,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('None', style: TextStyle(color: Colors.grey)),
                      ),
                      ..._users.map((user) {
                        return DropdownMenuItem(
                          value: user.id.toString(),
                          child: Text(user.displayname, style: TextStyle(color: Colors.yellow)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedHead = value;
                      });
                    },
                  ),
                
                  const SizedBox(height: 16),*/

                  // Cost Center Dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Cost Center',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.yellow),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    value: selectedCostCenter,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('None', style: TextStyle(color: Colors.grey)),
                      ),
                      ..._costCenters.map((center) {
                        return DropdownMenuItem(
                          value: center.id.toString(),
                          child: Text(center.name, style: TextStyle(color: Colors.yellow)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCostCenter = value;
                      });
                    },
                  ),
                
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active Department",
                            style: TextStyle(color: Colors.white, fontSize: 16)
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            onChanged: (bool value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                            inactiveTrackColor: Colors.transparent,
                            inactiveThumbColor: Colors.yellow.shade600,
                            activeColor: Colors.yellow[600],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Center(
                      child: Text(
                        "Assign HOD after employees registered",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Buttons Row
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
                      
                      // Create Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
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
                              onTap: _isSubmitting ? null : () async {
                                if (fullName.isNotEmpty) {
                                  try {
                                    setState(() {
                                      _isSubmitting = true;
                                    });

                                    final newDepartment = Department(
                                      id: 0,
                                      name: fullName,
                                      headId: selectedHead,
                                      costCenterId: selectedCostCenter,
                                      isActive: isActive,
                                    );

                                    await _createDepartment(newDepartment);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    setState(() {
                                      _isSubmitting = false;
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please fill all required fields')),
                                  );
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
                                        'Create',
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

}