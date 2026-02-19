// lib/features/user_creations/widgets/user_creation_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_creation_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/color_generator.dart';

class UserCreationCard extends StatefulWidget {
  final UserCreation userCreation;
  final bool isExpanded;
  final VoidCallback onTap;
  final Function(String, String) onApprove;
  final Function() onReject;
  final List<Department> availableDepartments;

  const UserCreationCard({
    Key? key,
    required this.userCreation,
    required this.isExpanded,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.availableDepartments,
  }) : super(key: key);

  @override
  _UserCreationCardState createState() => _UserCreationCardState();
}

class _UserCreationCardState extends State<UserCreationCard> {
  String? _tempSelectedRole;
  String? _tempSelectedDepartmentId;

  // Available roles with display names
  final Map<String, String> _availableRoles = {
    'employee': 'Employee',
    'admin': 'HOD',
    'hr': 'HR',
    'security': 'Security',
    'driver': 'Driver',
    'supervisor': 'Transport Supervisor',
  };

  @override
  void initState() {
    super.initState();
    // Initialize temp values when expanded
    if (widget.isExpanded) {
      _tempSelectedRole = widget.userCreation.role.name;
      _tempSelectedDepartmentId = _getSafeDepartmentId();
    }
  }

  @override
  void didUpdateWidget(UserCreationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset temp values when expansion state changes
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _tempSelectedRole = widget.userCreation.role.name;
      _tempSelectedDepartmentId = _getSafeDepartmentId();
    }
  }

  String _getSafeDepartmentId() {
    if (widget.availableDepartments.isEmpty) return '';

    if (widget.userCreation.departmentId != null) {
      final userDeptId = widget.userCreation.departmentId.toString();
      if (widget.availableDepartments.any(
        (dept) => dept.id.toString() == userDeptId,
      )) {
        return userDeptId;
      }
    }

    return widget.availableDepartments.first.id.toString();
  }

  String _getRoleDisplayName(String role) {
    return _availableRoles[role] ?? role;
  }

  String _getRoleBackendValue(String displayName) {
    return _availableRoles.entries
        .firstWhere(
          (entry) => entry.value == displayName,
          orElse: () => MapEntry(displayName.toLowerCase(), displayName),
        )
        .key;
  }

  String _getDepartmentName(String? departmentId) {
    if (departmentId == null) return 'Not Assigned';
    try {
      final department = widget.availableDepartments.firstWhere(
        (dept) => dept.id.toString() == departmentId,
      );
      return department.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  bool get _canApprove {
    if (widget.userCreation.isApproved != 'pending') return false;
    return _tempSelectedDepartmentId != null &&
        _tempSelectedDepartmentId!.isNotEmpty;
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
    final shortName = _generateShortName(widget.userCreation.displayname);
    final backgroundColor = ColorGenerator.getRandomColor(
      widget.userCreation.displayname,
    );
    final status = widget.userCreation.isApproved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: widget.isExpanded
                  ? Border.all(
                      color: backgroundColor.withOpacity(0.2),
                      width: 2,
                    )
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
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userCreation.displayname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.userCreation.email,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    _buildStatusBadge(status),

                    // Expand/Collapse Arrow
                    Transform.rotate(
                      angle: widget.isExpanded ? -1.5708 : 1.5708,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Expanded Details
                if (widget.isExpanded) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 16),

                  // Contact Info
                  _buildInfoRow(Icons.phone, widget.userCreation.phone),
                  _buildInfoRow(Icons.email, widget.userCreation.email),

                  const SizedBox(height: 16),

                  // Editable or Read-only fields
                  if (status == 'pending') ...[
                    _buildRoleDropdown(),
                    const SizedBox(height: 12),
                    _buildDepartmentDropdown(),

                    if (!_canApprove) _buildDepartmentWarning(),

                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      children: [
                        _buildDetailItem(
                          icon: Icons.person,
                          title: 'Role',
                          value: _getRoleDisplayName(
                            widget.userCreation.role.name,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildDetailItem(
                          icon: Icons.business,
                          title: 'Department',
                          value:
                              widget.userCreation.departmentName ??
                              'Not Assigned',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Request Date
                  Row(
                    children: [
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: 'Requested',
                        value:
                            widget.userCreation.createdAt
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            'N/A',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      // Reject Button
                      if (status == 'pending' || status == 'approved')
                        Expanded(
                          child: _buildActionButton(
                            label: status == 'approved'
                                ? 'Change to Reject'
                                : 'Reject',
                            color: Colors.red,
                            onTap: widget.onReject,
                          ),
                        ),

                      if (status == 'pending' || status == 'approved')
                        const SizedBox(width: 12),

                      // Approve Button
                      if (status == 'pending' || status == 'rejected')
                        Expanded(
                          child: _buildActionButton(
                            label: status == 'rejected'
                                ? 'Change to Approve'
                                : 'Approve',
                            color: Colors.green,
                            onTap: _canApprove
                                ? () => widget.onApprove(
                                    _tempSelectedRole ??
                                        widget.userCreation.role.name,
                                    _tempSelectedDepartmentId ?? '',
                                  )
                                : null,
                            isDisabled: status == 'pending' && !_canApprove,
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
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
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
              const SizedBox(width: 6),
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
          const SizedBox(height: 4),
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

  Widget _buildRoleDropdown() {
    final displayValue = _getRoleDisplayName(
      _tempSelectedRole ?? widget.userCreation.role.name,
    );
    final displayItems = _availableRoles.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'User Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayValue,
              isExpanded: true,
              items: displayItems.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (displayName) {
                if (displayName != null) {
                  setState(() {
                    _tempSelectedRole = _getRoleBackendValue(displayName);
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'Department *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _tempSelectedDepartmentId,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Select Department'),
              ),
              items: widget.availableDepartments.map((dept) {
                return DropdownMenuItem(
                  value: dept.id.toString(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(dept.name),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tempSelectedDepartmentId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentWarning() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Please select a department before approval',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final buttonColor = isDisabled ? Colors.grey : color;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: buttonColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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

}
