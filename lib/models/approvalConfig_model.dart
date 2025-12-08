class ApprovalConfiguration {
  final int id;
  final double? distanceLimit; // Change from String? to double?
  final int? secondaryApprovalUserId;
  final String? secondaryApprovalUserName;
  final int? safetyDeptApprovalUserId;
  final String? safetyDeptApprovalUserName;
  final String? restrictedFrom;
  final String? restrictedTo;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApprovalConfiguration({
    required this.id,
    this.distanceLimit,
    this.secondaryApprovalUserId,
    this.secondaryApprovalUserName,
    this.safetyDeptApprovalUserId,
    this.safetyDeptApprovalUserName,
    this.restrictedFrom,
    this.restrictedTo,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ApprovalConfiguration.fromJson(Map<String, dynamic> json) {
    return ApprovalConfiguration(
      id: json['_id'] ?? json['id'] ?? 0,
      distanceLimit: _parseDouble(json['distanceLimit']),
      // Safe access with null checks
      secondaryApprovalUserId: json['secondaryUser']?['id'],
      secondaryApprovalUserName: json['secondaryUser']?['displayname'],
      safetyDeptApprovalUserId: json['safetyUser']?['id'],
      safetyDeptApprovalUserName: json['safetyApprovalUser']?['displayname'] ?? json['safetyUser']?['displayname'],
      restrictedFrom: json['restrictedFrom'],
      restrictedTo: json['restrictedTo'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'distanceLimit': distanceLimit,
      'secondaryUserId': secondaryApprovalUserId,
      'safetyUserId': safetyDeptApprovalUserId,
      'restrictedFrom': restrictedFrom,
      'restrictedTo': restrictedTo,
      'isActive': isActive,
    };
  }
}