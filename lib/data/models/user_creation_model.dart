import 'user_model.dart';

class UserCreation {
  final int id;
  final String displayname;
  final String email;
  final String phone;
  final int? departmentId;
  final String? departmentName;
  final UserRole role;
  final String isApproved; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserCreation({
    required this.id,
    required this.displayname,
    required this.email,
    required this.phone,
    this.departmentId,
    this.departmentName,
    required this.role,
    required this.isApproved,
    this.createdAt,
    this.updatedAt,
  });

  factory UserCreation.fromJson(Map<String, dynamic> json) {
    return UserCreation(
      id: json['id'] ?? 0,
      displayname: json['displayname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      departmentId: json['department']?['id'] ?? 0,
      departmentName: json['department']?['name'] ?? null,
      role: _parseUserRole(json['role']),
      isApproved: json['isApproved'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static UserRole _parseUserRole(dynamic role) {
    if (role is String) {
      switch (role.toLowerCase()) {
        case 'admin': return UserRole.admin;
        case 'hr': return UserRole.hr;
        //case 'sysadmin': return UserRole.sysadmin;
        case 'security': return UserRole.security;
        case 'driver': return UserRole.driver;
        default: return UserRole.employee;
      }
    } else if (role is Map<String, dynamic>) {
      final roleName = role['name'] ?? role['role'] ?? 'employee';
      return _parseUserRole(roleName);
    }
    return UserRole.employee;
  }
}
