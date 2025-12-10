import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/approvalConfig_model.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/admin/approval_user_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class ApprovalManagementScreen extends StatefulWidget {
  final VoidCallback? onApprovalUsersPressed;

  const ApprovalManagementScreen({Key? key, this.onApprovalUsersPressed}) : super(key: key);

  @override
  _ApprovalManagementScreenState createState() => _ApprovalManagementScreenState();
}

class _ApprovalManagementScreenState extends State<ApprovalManagementScreen> {
  ApprovalConfiguration? _approvalConfig;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadApprovalConfiguration();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
  
  Widget _buildApprovalUsersButton() {
  return Container(
    width: double.infinity,
    height: 46,
    decoration: BoxDecoration(
      color: Colors.green,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.3),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onApprovalUsersPressed, // Use the callback here
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Approval Users Management',
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
  );
}

  Future<void> _loadApprovalConfiguration() async {
    try {
      final response = await ApiService.getApprovalConfig();
      
      if (response['success'] == true) {
        final data = response['data'];
        
        // Handle different possible response structures
        List<dynamic> configs;
        
        if (data is List) {
          // If data is directly a list
          configs = data;
        } else if (data['approvalConfigs'] is List) {
          // If data contains approvalConfigs list
          configs = data['approvalConfigs'] as List<dynamic>;
        } else if (data['approvalConfig'] is Map) {
          // If data contains a single approvalConfig object
          configs = [data['approvalConfig']];
        } else {
          configs = [];
        }
        
        setState(() {
          if (configs.isNotEmpty) {
            try {
              _approvalConfig = ApprovalConfiguration.fromJson(configs.first);
            } catch (e) {
              print('Error parsing configuration: $e');
              _approvalConfig = null;
              _hasError = true;
              _errorMessage = 'Failed to parse configuration data';
            }
          } else {
            _approvalConfig = null;
          }
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load approval configuration');
      }
    } catch (e) {
      print('Error loading approval configuration: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Build user selection widget
  Widget _buildUserSelectionField({
    required String label,
    required String? selectedUserName,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? '*' : ''}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedUserName ?? 'Select $label',
                    style: TextStyle(
                      color: selectedUserName != null ? Colors.yellow : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (selectedUserName != null) ...[
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 18),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Show user selection dialog
  Future<Map<String, dynamic>?> _showUserSelectionDialog({
    required String title,
    required String? currentSelection,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        // Local state for the dialog
        List<Map<String, dynamic>> localSearchResults = [];
        bool localIsSearching = false;
        String localSearchQuery = '';
        TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            
            Future<void> _performSearch(String query) async {
              try {
                final response = await ApiService.searchUsers(query);
                if (response['success'] == true) {
                  final usersData = response['data']['users'] as List<dynamic>;
                  setState(() {
                    localSearchResults = usersData
                        .map(
                          (data) => {
                            'id': data['_id'] ?? data['id'],
                            'displayName':
                                data['displayName'] ??
                                data['displayname'] ??
                                'Unknown',
                          },
                        )
                        .toList();
                    localIsSearching = false;
                  });
                } else {
                  throw Exception(
                    response['message'] ?? 'Failed to search users',
                  );
                }
              } catch (e) {
                print('Error searching users: $e');
                setState(() {
                  localSearchResults = [];
                  localIsSearching = false;
                });
              }
            }

            // Local search function for the dialog
            Future<void> localSearchUsers(String query) async {
              if (query.isEmpty) {
                setState(() {
                  localSearchResults = [];
                  localIsSearching = false;
                });
                return;
              }

              // Cancel previous timer
              _searchTimer?.cancel();

              setState(() {
                localIsSearching = true;
              });

              // Create new timer with delay
              _searchTimer = Timer(const Duration(milliseconds: 500), () async {
                await _performSearch(query);
              });

            }

            return Dialog(
              backgroundColor: Colors.black.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 500,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Search field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: TextStyle(color: Colors.yellow),
                            decoration: InputDecoration(
                              labelText: 'Search users by name',
                              labelStyle: TextStyle(color: Colors.grey),
                              floatingLabelStyle: TextStyle(color: Colors.yellow),
                              prefixIcon: Icon(Icons.search, color: Colors.yellow),
                              suffixIcon: localSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.cancel, color: Colors.red, size: 20),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          localSearchQuery = '';
                                          localSearchResults = [];
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
                                localSearchQuery = query;
                              });
                              localSearchUsers(query);
                            },
                          ),
                        ),
                        // Remove the external clear button since it's now inside the field
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Search results
                    Expanded(
                      child: localIsSearching
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.yellow[600],
                              ),
                            )
                          : localSearchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    localSearchQuery.isEmpty 
                                        ? 'Start typing to search users'
                                        : 'No users found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: localSearchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = localSearchResults[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          user['displayName'].isNotEmpty 
                                              ? user['displayName'][0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(
                                        user['displayName'],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      trailing: currentSelection == user['displayName']
                                          ? Icon(Icons.check, color: Colors.yellow)
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context, user);
                                      },
                                    );
                                  },
                                ),
                    ),
                    
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[600],
                            ),
                            onPressed: () => Navigator.pop(context, null),
                            child: Text('Clear', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _createApprovalConfiguration(ApprovalConfiguration config, {BuildContext? dialogContext}) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final response = await ApiService.createApprovalConfig(config.toJson());
      
      if (response['success'] == true) {
        final newConfigData = response['data']['approvalConfig'];
        setState(() {
          _approvalConfig = ApprovalConfiguration.fromJson(newConfigData);
        });
        
        // Close the dialog if context is provided
        if (dialogContext != null && Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval configuration created successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create approval configuration');
      }
    } catch (e) {
      print('Error creating approval configuration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create approval configuration: $e')),
      );
      rethrow;
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _updateApprovalConfiguration(ApprovalConfiguration config, {BuildContext? dialogContext}) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final response = await ApiService.updateApprovalConfig(config.id, config.toJson());
      
      if (response['success'] == true) {
        final updatedConfigData = response['data']['approvalConfig'];
        setState(() {
          _approvalConfig = ApprovalConfiguration.fromJson(updatedConfigData);
        });
        
        // Close the dialog if context is provided
        if (dialogContext != null && Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval configuration updated successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update approval configuration');
      }
    } catch (e) {
      print('Error updating approval configuration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update approval configuration: $e')),
      );
      rethrow;
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
              'Error Loading Configuration',
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
              onPressed: _loadApprovalConfiguration,
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
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approval Configuration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // ADDED: Approval Users Creation Button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildApprovalUsersButton(),
        ),

        // Create/Edit Button Section
        Padding(
          padding: EdgeInsets.all(20),
          child: _approvalConfig == null 
              ? _buildCreateConfigButton()
              : _buildEditConfigButton(),
        ),

        SizedBox(height: 8),
        
        // Configuration Card or Empty State
        Expanded(
          child: _approvalConfig == null 
              ? _buildEmptyState()
              : _buildConfigCard(),
        ),
      ],
    ),
  );
}

  Widget _buildCreateConfigButton() {
    return Container(
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
          onTap: _isSubmitting ? null : () {
            _showCreateConfigDialog();
          },
          child: Center(
            child: _isSubmitting
                ? CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create Configuration',
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
    );
  }

  Widget _buildEditConfigButton() {
    return Container(
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
          onTap: _isSubmitting ? null : () {
            _showEditConfigDialog();
          },
          child: Center(
            child: _isSubmitting
                ? CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Edit Configuration',
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.approval,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Configuration Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create approval configuration to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2), 
                width: 2
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Configuration Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.approval,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Configuration Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approval Configuration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(height: 20),

                _buildConfigItem(
                icon: Icons.person,
                title: 'Primary Approval',
                value: 'Department Head',
                description: 'Configured in Department Basic Data',
              ),
              
              SizedBox(height: 20),
                
                // Distance Limit
                _buildConfigItem(
                  icon: Icons.place,
                  title: 'Distance Limit',
                  value: _approvalConfig!.distanceLimit != null 
                      ? '${_approvalConfig!.distanceLimit} km'
                      : 'Not set',
                ),
                
                SizedBox(height: 20),
                
                // Secondary Approval User
                _buildConfigItem(
                  icon: Icons.supervisor_account,
                  title: 'Secondary Approval User',
                  value: _approvalConfig!.secondaryApprovalUserName ?? 'Not assigned',
                ),
                
                SizedBox(height: 20),
                
                // Restricted Hours
                _buildConfigItem(
                  icon: Icons.access_time,
                  title: 'Restricted Hours',
                  value: _approvalConfig!.restrictedFrom != null && _approvalConfig!.restrictedTo != null
                      ? '${_approvalConfig!.restrictedFrom} - ${_approvalConfig!.restrictedTo}'
                      : 'Not set',
                ),
                
                SizedBox(height: 20),
                
                // Safety Dept Approval User
                _buildConfigItem(
                  icon: Icons.security,
                  title: 'Safety Dept Approval User',
                  value: _approvalConfig!.safetyDeptApprovalUserName ?? 'Not assigned',
                ),

                SizedBox(height: 20),

                // Status and Timestamps
                Row(
                  children: [
                    _buildDetailItem(
                      icon: Icons.circle,
                      title: 'Status',
                      value: _approvalConfig!.isActive ? 'Active' : 'Inactive',
                      valueColor: _approvalConfig!.isActive ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 24),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      title: 'Updated At',
                      value: _approvalConfig!.updatedAt != null 
                          ? _formatDate(_approvalConfig!.updatedAt!)
                          : 'N/A',
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildConfigItem({
    required IconData icon,
    required String title,
    required String value,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
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

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  void _showCreateConfigDialog() {
    String distanceLimit = '';
    Map<String, dynamic>? selectedSecondaryUser;
    Map<String, dynamic>? selectedSafetyUser;
    TimeOfDay? restrictedFrom;
    TimeOfDay? restrictedTo;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return _buildConfigDialog(
            title: 'Approval Configuration',
            isEditing: false,
            distanceLimit: distanceLimit,
            selectedSecondaryUser: selectedSecondaryUser,
            selectedSafetyUser: selectedSafetyUser,
            restrictedFrom: restrictedFrom,
            restrictedTo: restrictedTo,
            isActive: isActive,
            onDistanceLimitChanged: (value) => setState(() => distanceLimit = value),
            onSecondaryUserChanged: (user) => setState(() => selectedSecondaryUser = user),
            onSafetyUserChanged: (user) => setState(() => selectedSafetyUser = user),
            onRestrictedFromChanged: (time) => setState(() => restrictedFrom = time),
            onRestrictedToChanged: (time) => setState(() => restrictedTo = time),
            onIsActiveChanged: (value) => setState(() => isActive = value),
            onSave: () async {
              // Validate and parse distance limit
              double? parsedDistanceLimit;
              if (distanceLimit.isNotEmpty) {
                parsedDistanceLimit = double.tryParse(distanceLimit);
                if (parsedDistanceLimit == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid number for distance limit')),
                  );
                  return;
                }
              }

              final error = _validateConfig(
                distanceLimit: distanceLimit,
                secondaryApprovalUser: selectedSecondaryUser?['displayName'],
                restrictedFrom: restrictedFrom,
                restrictedTo: restrictedTo,
                safetyDeptApprovalUser: selectedSafetyUser?['displayName'],
              );
              
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
                return;
              }

              try {
                final newConfig = ApprovalConfiguration(
                  id: 0,
                  distanceLimit: parsedDistanceLimit,
                  secondaryApprovalUserId: selectedSecondaryUser?['id'],
                  secondaryApprovalUserName: selectedSecondaryUser?['displayName'],
                  safetyDeptApprovalUserId: selectedSafetyUser?['id'],
                  safetyDeptApprovalUserName: selectedSafetyUser?['displayName'],
                  restrictedFrom: restrictedFrom != null 
                      ? '${restrictedFrom!.hour}:${restrictedFrom!.minute.toString().padLeft(2, '0')}'
                      : null,
                  restrictedTo: restrictedTo != null
                      ? '${restrictedTo!.hour}:${restrictedTo!.minute.toString().padLeft(2, '0')}'
                      : null,
                  isActive: isActive,
                );
                
                await _createApprovalConfiguration(newConfig, dialogContext: dialogContext);
              } catch (e) {
                // Error handling is done in _createApprovalConfiguration
              }
            },
            distanceLimitController: null,
          );
        },
      ),
    );
  }
  
  void _showEditConfigDialog() {
    // Convert existing distance limit to string for editing
    String distanceLimit = _approvalConfig!.distanceLimit?.toString() ?? '';
    Map<String, dynamic>? selectedSecondaryUser;
    Map<String, dynamic>? selectedSafetyUser;
    
    // Set initial selected users if they exist
    if (_approvalConfig!.secondaryApprovalUserId != null) {
      selectedSecondaryUser = {
        'id': _approvalConfig!.secondaryApprovalUserId,
        'displayName': _approvalConfig!.secondaryApprovalUserName ?? 'Unknown User',
      };
    }
    
    if (_approvalConfig!.safetyDeptApprovalUserId != null) {
      selectedSafetyUser = {
        'id': _approvalConfig!.safetyDeptApprovalUserId,
        'displayName': _approvalConfig!.safetyDeptApprovalUserName ?? 'Unknown User',
      };
    }
    
    TimeOfDay? restrictedFrom = _parseTime(_approvalConfig!.restrictedFrom);
    TimeOfDay? restrictedTo = _parseTime(_approvalConfig!.restrictedTo);
    bool isActive = _approvalConfig!.isActive;

    // Create a text controller for the distance limit field
    TextEditingController distanceLimitController = TextEditingController(text: distanceLimit);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return _buildConfigDialog(
            title: 'Edit Approval Configuration',
            isEditing: true,
            distanceLimit: distanceLimit,
            selectedSecondaryUser: selectedSecondaryUser,
            selectedSafetyUser: selectedSafetyUser,
            restrictedFrom: restrictedFrom,
            restrictedTo: restrictedTo,
            isActive: isActive,
            onDistanceLimitChanged: (value) => setState(() => distanceLimit = value),
            onSecondaryUserChanged: (user) => setState(() => selectedSecondaryUser = user),
            onSafetyUserChanged: (user) => setState(() => selectedSafetyUser = user),
            onRestrictedFromChanged: (time) => setState(() => restrictedFrom = time),
            onRestrictedToChanged: (time) => setState(() => restrictedTo = time),
            onIsActiveChanged: (value) => setState(() => isActive = value),
            onSave: () async {
              // Validate and parse distance limit
              double? parsedDistanceLimit;
              if (distanceLimit.isNotEmpty) {
                parsedDistanceLimit = double.tryParse(distanceLimit);
                if (parsedDistanceLimit == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid number for distance limit')),
                  );
                  return;
                }
              }

              final error = _validateConfig(
                distanceLimit: distanceLimit,
                secondaryApprovalUser: selectedSecondaryUser?['displayName'],
                restrictedFrom: restrictedFrom,
                restrictedTo: restrictedTo,
                safetyDeptApprovalUser: selectedSafetyUser?['displayName'],
              );
              
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
                return;
              }

              try {
                final updatedConfig = ApprovalConfiguration(
                  id: _approvalConfig!.id,
                  distanceLimit: parsedDistanceLimit,
                  secondaryApprovalUserId: selectedSecondaryUser?['id'],
                  secondaryApprovalUserName: selectedSecondaryUser?['displayName'],
                  safetyDeptApprovalUserId: selectedSafetyUser?['id'],
                  safetyDeptApprovalUserName: selectedSafetyUser?['displayName'],
                  restrictedFrom: restrictedFrom != null 
                      ? '${restrictedFrom!.hour}:${restrictedFrom!.minute.toString().padLeft(2, '0')}'
                      : null,
                  restrictedTo: restrictedTo != null
                      ? '${restrictedTo!.hour}:${restrictedTo!.minute.toString().padLeft(2, '0')}'
                      : null,
                  isActive: isActive,
                  createdAt: _approvalConfig!.createdAt,
                  updatedAt: _approvalConfig!.updatedAt,
                );
                
                await _updateApprovalConfiguration(updatedConfig, dialogContext: dialogContext);
              } catch (e) {
                // Error handling is done in _updateApprovalConfiguration
              }
            },
            distanceLimitController: distanceLimitController,
          );
        },
      ),
    );
  }
  
  Widget _buildConfigDialog({
    required String title,
    required bool isEditing,
    required String distanceLimit,
    required Map<String, dynamic>? selectedSecondaryUser,
    required Map<String, dynamic>? selectedSafetyUser,
    required TimeOfDay? restrictedFrom,
    required TimeOfDay? restrictedTo,
    required bool isActive,
    required Function(String) onDistanceLimitChanged,
    required Function(Map<String, dynamic>?) onSecondaryUserChanged,
    required Function(Map<String, dynamic>?) onSafetyUserChanged,
    required Function(TimeOfDay?) onRestrictedFromChanged,
    required Function(TimeOfDay?) onRestrictedToChanged,
    required Function(bool) onIsActiveChanged,
    required Function() onSave,
    TextEditingController? distanceLimitController,
  }) {
    bool hasDistanceLimit = distanceLimit.isNotEmpty;
    bool hasRestrictedHours = restrictedFrom != null && restrictedTo != null;

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
            // Title
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 30),

            // Distance Limit Field - Updated to use controller
            TextField(
              controller: distanceLimitController, // Use the controller
              style: TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                labelText: 'Distance Limit (km)',
                labelStyle: TextStyle(color: Colors.grey),
                floatingLabelStyle: TextStyle(color: Colors.yellow),
                prefixIcon: Icon(Icons.place, color: Colors.yellow),
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
                hintText: 'e.g., 50',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              keyboardType: TextInputType.number,
              onChanged: onDistanceLimitChanged,
            ),
            SizedBox(height: 16),

            // Secondary Approval User Selection
            _buildUserSelectionField(
              label: 'Secondary Approval User',
              selectedUserName: selectedSecondaryUser?['displayName'],
              isRequired: hasDistanceLimit,
              onTap: () async {
                final user = await _showUserSelectionDialog(
                  title: 'Select Secondary Approval User',
                  currentSelection: selectedSecondaryUser?['displayName'],
                );
                if (user != null) {
                  onSecondaryUserChanged(user);
                }
              },
              onClear: () => onSecondaryUserChanged(null),
            ),
            SizedBox(height: 16),

            // Restricted Hours Section
            Text(
              'Restricted Hours',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            
            // Time Fields
            Column(
              children: [
                _buildTimeField(
                  'From',
                  restrictedFrom,
                  () => _selectTime(context, onRestrictedFromChanged),
                  onClear: restrictedFrom != null ? () => onRestrictedFromChanged(null) : null,
                ),
                SizedBox(height: 12),
                _buildTimeField(
                  'To',
                  restrictedTo,
                  () => _selectTime(context, onRestrictedToChanged),
                  onClear: restrictedTo != null ? () => onRestrictedToChanged(null) : null,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Safety Dept Approval User Selection
            _buildUserSelectionField(
              label: 'Safety Dept Approval User',
              selectedUserName: selectedSafetyUser?['displayName'],
              isRequired: hasRestrictedHours,
              onTap: () async {
                final user = await _showUserSelectionDialog(
                  title: 'Select Safety Dept Approval User',
                  currentSelection: selectedSafetyUser?['displayName'],
                );
                if (user != null) {
                  onSafetyUserChanged(user);
                }
              },
              onClear: () => onSafetyUserChanged(null),
            ),
            SizedBox(height: 8),

            // Active/Inactive Toggle
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Active Configuration",
                      style: TextStyle(color: Colors.white, fontSize: 16)
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      onChanged: onIsActiveChanged,
                      inactiveTrackColor: Colors.transparent,
                      inactiveThumbColor: Colors.yellow.shade600,
                      activeColor: Colors.yellow[600],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),

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
                SizedBox(width: 12),
                
                // Save Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (_isSubmitting ? Colors.grey : Colors.yellow)!.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isSubmitting ? null : onSave,
                        child: Center(
                          child: _isSubmitting
                              ? CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                )
                              : Text(
                                  isEditing ? 'Save' : 'Create',
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
  }

  Widget _buildTimeField(String label, TimeOfDay? time, VoidCallback onTap, {VoidCallback? onClear}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Text(
                  time != null 
                    ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                    : 'Select time',
                  style: TextStyle(
                    color: time != null ? Colors.yellow : Colors.grey.shade600,
                  ),
                ),
                Spacer(),
                if (time != null && onClear != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 18),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                Icon(
                  Icons.access_time,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, Function(TimeOfDay?) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  String? _validateConfig({
    required String distanceLimit,
    required String? secondaryApprovalUser,
    required TimeOfDay? restrictedFrom,
    required TimeOfDay? restrictedTo,
    required String? safetyDeptApprovalUser,
  }) {
    if (distanceLimit.isNotEmpty && (secondaryApprovalUser == null || secondaryApprovalUser.isEmpty)) {
      return 'Secondary Approval User is required when Distance Limit is set';
    }
    
    if (restrictedFrom != null && restrictedTo != null && (safetyDeptApprovalUser == null || safetyDeptApprovalUser.isEmpty)) {
      return 'Safety Dept Approval User is required when Restricted Hours are set';
    }
    
    return null; // No error
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

}