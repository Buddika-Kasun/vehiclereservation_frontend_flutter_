import 'package:vehiclereservation_frontend_flutter_/models/department_model.dart';

enum UserRole {
  sysadmin('sysadmin', 'System Administrator'),
  employee('employee', 'Employee'),
  driver('driver', 'Driver'),
  admin('admin', 'Administrator'),
  hr('hr', 'HR'),
  security('security', 'Security');

  const UserRole(this.value, this.displayName);
  final String value;
  final String displayName;

  static UserRole fromString(String role) {
    for (final userRole in UserRole.values) {
      if (userRole.value == role.toLowerCase()) {
        return userRole;
      }
    }
    return UserRole.employee;
  }
}

class User {
  final int id;
  final String username;
  final String displayname;
  final String email;
  final String phone;
  final UserRole role; // Use enum
  final String? department;
  final bool isActive;
  final String isApproved;
  final String? profilePicture;
  final int authenticationLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.displayname,
    required this.email,
    required this.phone,
    required this.role,
    this.department,
    required this.isActive,
    required this.isApproved,
    this.profilePicture,
    required this.authenticationLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      displayname: json['displayname'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRole.fromString(json['role'] as String),
      department: json['department']?['name'],
      isActive: json['isActive'] as bool,
      isApproved: json['isApproved'],
      profilePicture: json['profilePicture'],
      authenticationLevel: json['authenticationLevel'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayname': displayname,
      'email': email,
      'phone': phone,
      'role': role.value, // Use .value to get string
      'isActive': isActive,
      'isApproved': isApproved,
      'profilePicture': profilePicture,
      'authenticationLevel': authenticationLevel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for role checking
  bool get isAdmin => role == UserRole.admin || role == UserRole.sysadmin;
  bool get isDriver => role == UserRole.driver;
  bool get isSecurity => role == UserRole.security;
  bool get isHr => role == UserRole.hr;
  bool get isEmployee => role == UserRole.employee;
}

class ShortUser {
  final int id;
  final String displayname;

  ShortUser({
    required this.id,
    required this.displayname,
  });

  factory ShortUser.fromJson(Map<String, dynamic> json) {
    return ShortUser(
      id: json['id'] as int,
      displayname: json['displayname'] as String,
    );
  }
}