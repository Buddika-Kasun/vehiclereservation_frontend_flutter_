class Department {
  final int id;
  final String name;
  final int? employees;
  final String? headId;
  final String? headName;
  final String? costCenterId;
  final String? costCenterName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Department({
    required this.id,
    required this.name,
    this.employees,
    this.headId,
    this.headName,
    this.costCenterId,
    this.costCenterName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
  
  // Handle headOfDepartment - could be string, object, or null
  dynamic headData = json['headOfDepartment'] ?? json['head'];
  String headId = '';
  String headName = 'Not Assign';
  
  if (headData != null) {
    if (headData is String) {
      // If it's a string, use it as the name
      headName = headData;
    } else if (headData is Map<String, dynamic>) {
      // If it's an object, extract id and name
      headId = headData['id']?.toString() ?? '';
      headName = headData['displayname'] ?? '';
    }
  }
  
  // Handle costCenter - could be string, object, or null
  dynamic costCenterData = json['costCenter'];
  String costCenterId = '';
  String costCenterName = 'Not Assign';
  
  if (costCenterData != null) {
    if (costCenterData is String) {
      // If it's a string, use it as the name
      costCenterName = costCenterData;
    } else if (costCenterData is Map<String, dynamic>) {
      // If it's an object, extract id and name
      costCenterId = costCenterData['id']?.toString() ?? '';
      costCenterName = costCenterData['name'] ?? '';
    }
  }
  
  return Department(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    employees: json['employees'] ?? json['employeeCount'] ?? 0,
    headId: headId,
    headName: headName,
    costCenterId: costCenterId,
    costCenterName: costCenterName,
    isActive: json['isActive'] ?? true,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'])
        : null,
    updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'])
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'headId': headId,
      'costCenterId': costCenterId,
      'isActive': isActive,
    };
  }
}