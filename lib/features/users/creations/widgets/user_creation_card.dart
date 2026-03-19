// lib/features/user_creations/widgets/user_creation_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_creation_model.dart';
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

    // Trim and split by whitespace (handles multiple spaces)
    final words = displayName.trim().split(RegExp(r'\s+'));

    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    // Handle single word or empty after trim
    final firstWord = words.isNotEmpty ? words[0] : '';
    return firstWord.isNotEmpty ? firstWord[0].toUpperCase() : 'U';
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
              //color: backgroundColor.withOpacity(0.1),
              color: Colors.grey[900]!,
              borderRadius: BorderRadius.circular(12),
              border: widget.isExpanded
                  ? Border.all(
                      color: Colors.grey.withOpacity(0.1),
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
                              //color: Colors.black,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1, 
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.userCreation.email,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              //color: Colors.grey[700],
                              color: Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1, 
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

                  const SizedBox(height: 4),

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
                            onTap: _showRejectConfirmation,
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
                            onTap: status == 'rejected'
                                ? _showChangeToApproveConfirmation // Show change to approve dialog
                                : (_canApprove
                                      ? _showApproveConfirmation
                                      : null),
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
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
    Color valueColor = Colors.white,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[300]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[300],
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
            Icon(Icons.person, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            const Text(
              'User Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 209, 209, 209),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[600]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayValue,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.yellow, fontSize: 14),
              items: displayItems.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.toUpperCase(),
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
            Icon(Icons.business, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            const Text(
              'Department *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 209, 209, 209),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[600]!),
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
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.yellow, fontSize: 14),
              items: widget.availableDepartments.map((dept) {
                return DropdownMenuItem(
                  value: dept.id.toString(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      dept.name,
                    ),
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
        backgroundColor = Colors.greenAccent;
        textColor = Colors.greenAccent;
        statusText = 'Approved';
        break;
      case 'rejected':
        backgroundColor = Colors.redAccent;
        textColor = Colors.redAccent;
        statusText = 'Rejected';
        break;
      default:
        backgroundColor = Colors.orangeAccent;
        textColor = Colors.orangeAccent;
        statusText = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
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

  void _showRejectConfirmation() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool _isSubmitting = false;
          final currentStatus = widget.userCreation.isApproved;

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
                        ? 'Are you sure you want to change ${widget.userCreation.displayname} from Approved to Rejected?'
                        : 'Are you sure you want to reject ${widget.userCreation.displayname}?',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
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
                            boxShadow: _isSubmitting
                                ? []
                                : [
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
                              onTap: _isSubmitting
                                  ? null
                                  : () async {
                                      try {
                                        setState(() {
                                          _isSubmitting = true;
                                        });
                                        Navigator.pop(context);
                                        await widget.onReject();
                                      } catch (e) {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    },
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Reject',
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

  void _showApproveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool _isSubmitting = false;
          final departmentName = _getDepartmentName(_tempSelectedDepartmentId);
          final role = _tempSelectedRole ?? widget.userCreation.role.name;

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
                    'Are you sure you want to approve ${widget.userCreation.displayname}?',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role: ${_getRoleDisplayName(role)}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Department: $departmentName',
                          style: const TextStyle(
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
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
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
                            color: _isSubmitting ? Colors.grey : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting
                                  ? null
                                  : () async {
                                      try {
                                        setState(() {
                                          _isSubmitting = true;
                                        });
                                        Navigator.pop(context);
                                        await widget.onApprove(
                                          role,
                                          _tempSelectedDepartmentId ?? '',
                                        );
                                        //if (context.mounted) {
                                        //  Navigator.pop(context);
                                        //}
                                      } catch (e) {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    },
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Approve',
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

  void _showChangeToApproveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool _isSubmitting = false;
          final canApprove =
              _tempSelectedDepartmentId != null &&
              _tempSelectedDepartmentId!.isNotEmpty;

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
                    'Change ${widget.userCreation.displayname} from Rejected to Approved?',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Role Dropdown
                  _buildRoleDropdownNew(context, setState),

                  const SizedBox(height: 16),

                  // Department Dropdown
                  _buildDepartmentDropdownNew(context, setState),

                  if (!canApprove) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
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
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
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
                            color: _isSubmitting || !canApprove
                                ? Colors.grey
                                : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: (_isSubmitting || !canApprove)
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: (_isSubmitting || !canApprove)
                                  ? null
                                  : () async {
                                      try {
                                        setState(() {
                                          _isSubmitting = true;
                                        });
                                        Navigator.pop(context);
                                        await widget.onApprove(
                                          _tempSelectedRole ??
                                              widget.userCreation.role.name,
                                          _tempSelectedDepartmentId ?? '',
                                        );
                                        //if (context.mounted) {
                                        //  Navigator.pop(context);
                                        //}
                                      } catch (e) {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    },
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Approve',
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

  // Helper dropdown widgets for the change to approve dialog
  Widget _buildRoleDropdownNew(
    BuildContext dialogContext,
    StateSetter setState,
  ) {
    final displayValue = _getRoleDisplayName(
      _tempSelectedRole ?? widget.userCreation.role.name,
    );
    final displayItems = _availableRoles.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'User Role',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
            focusedBorder: const OutlineInputBorder(
              //borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.yellow, width: 1),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          value: displayValue,
          items: displayItems.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(color: Colors.yellow),
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
      ],
    );
  }

  Widget _buildDepartmentDropdownNew(
    BuildContext dialogContext,
    StateSetter setState,
  ) {
    String safeCurrentDepartmentId = _tempSelectedDepartmentId ?? '';

    if (widget.availableDepartments.isNotEmpty &&
        !widget.availableDepartments.any(
          (dept) => dept.id.toString() == safeCurrentDepartmentId,
        )) {
      safeCurrentDepartmentId = widget.availableDepartments.first.id.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Department *',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
            focusedBorder: const OutlineInputBorder(
              //borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.yellow, width: 1),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          value: safeCurrentDepartmentId.isNotEmpty
              ? safeCurrentDepartmentId
              : null,
          hint: const Text(
            'Select Department',
            style: TextStyle(color: Colors.grey),
          ),
          items: widget.availableDepartments.map((dept) {
            return DropdownMenuItem(
              value: dept.id.toString(),
              child: Text(
                dept.name,
                style: const TextStyle(color: Colors.yellow),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _tempSelectedDepartmentId = value;
            });
          },
        ),
      ],
    );
  }

}