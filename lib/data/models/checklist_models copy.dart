// models/checklist_models.dart

import 'package:flutter/material.dart';

class ChecklistResponse {
  final String id;
  final String vehicleId;
  final String vehicleRegNo;
  final DateTime checklistDate;
  final CheckedBy checkedBy; // Changed to object
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, ChecklistItemResponse> responses;
  final bool isSubmitted;
  final String? status;
  final CheckedBy? approvedBy;

  ChecklistResponse({
    required this.id,
    required this.vehicleId,
    required this.vehicleRegNo,
    required this.checklistDate,
    required this.checkedBy,
    required this.createdAt,
    this.updatedAt,
    required this.responses,
    required this.isSubmitted,
    this.status,
    this.approvedBy,
  });

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    print('🔄 Parsing ChecklistResponse from JSON');

    // Debug print to see what we're receiving
    print('JSON keys: ${json.keys}');
    print('checkedBy type: ${json['checkedBy']?.runtimeType}');
    print('responses type: ${json['responses']?.runtimeType}');

    // Parse checkedBy object with proper type checking
    CheckedBy checkedBy;
    try {
      if (json['checkedBy'] != null) {
        if (json['checkedBy'] is Map<String, dynamic>) {
          checkedBy = CheckedBy.fromJson(
            Map<String, dynamic>.from(json['checkedBy']),
          );
        } else if (json['checkedBy'] is Map) {
          // Handle generic Map
          checkedBy = CheckedBy.fromJson(
            Map<String, dynamic>.from(json['checkedBy'] as Map),
          );
        } else {
          print('⚠️ checkedBy is not a Map, using fallback');
          checkedBy = CheckedBy(id: '', name: '', role: '');
        }
      } else {
        print('⚠️ checkedBy is null, using fallback');
        checkedBy = CheckedBy(id: '', name: '', role: '');
      }
    } catch (e) {
      print('❌ Error parsing checkedBy: $e');
      checkedBy = CheckedBy(id: '', name: '', role: '');
    }

    CheckedBy? approvedBy;
    try {
      if (json['approvedBy'] != null) {
        if (json['approvedBy'] is Map<String, dynamic>) {
          approvedBy = CheckedBy.fromJson(
            Map<String, dynamic>.from(json['approvedBy']),
          );
        } else if (json['approvedBy'] is Map) {
          approvedBy = CheckedBy.fromJson(
            Map<String, dynamic>.from(json['approvedBy'] as Map),
          );
        } else {
          print('⚠️ approvedBy is not a Map, using fallback');
          approvedBy = null;
        }
      } else {
        print('⚠️ approvedBy is null, using fallback');
        approvedBy = null;
      }
    } catch (e) {
      print('❌ Error parsing approvedBy: $e');
      approvedBy = null;
    }

    // Parse responses with proper type checking
    Map<String, ChecklistItemResponse> responses = {};
    try {
      if (json['responses'] != null) {
        if (json['responses'] is Map<String, dynamic>) {
          final responsesMap = Map<String, dynamic>.from(json['responses']);
          responses = responsesMap.map((key, value) {
            try {
              if (value is Map<String, dynamic>) {
                return MapEntry(key, ChecklistItemResponse.fromJson(value));
              } else if (value is Map) {
                return MapEntry(
                  key,
                  ChecklistItemResponse.fromJson(
                    Map<String, dynamic>.from(value),
                  ),
                );
              } else {
                print(
                  '⚠️ Response value for $key is not a Map: $value (type: ${value.runtimeType})',
                );
                return MapEntry(
                  key,
                  ChecklistItemResponse(status: null, remarks: null),
                );
              }
            } catch (e) {
              print('⚠️ Error parsing response item $key: $e');
              return MapEntry(
                key,
                ChecklistItemResponse(status: null, remarks: null),
              );
            }
          });
        } else if (json['responses'] is Map) {
          // Handle generic Map
          final responsesMap = Map.from(json['responses'] as Map);
          responses = responsesMap.map((key, value) {
            try {
              if (value is Map) {
                return MapEntry(
                  key.toString(),
                  ChecklistItemResponse.fromJson(
                    Map<String, dynamic>.from(value),
                  ),
                );
              } else {
                print('⚠️ Response value for $key is not a Map: $value');
                return MapEntry(
                  key.toString(),
                  ChecklistItemResponse(status: null, remarks: null),
                );
              }
            } catch (e) {
              print('⚠️ Error parsing response item $key: $e');
              return MapEntry(
                key.toString(),
                ChecklistItemResponse(status: null, remarks: null),
              );
            }
          });
        } else {
          print('⚠️ responses is not a Map: ${json['responses']}');
        }
      } else {
        print('⚠️ responses is null');
      }
    } catch (e) {
      print('❌ Error parsing responses: $e');
      responses = {};
    }

    // Parse dates with error handling
    DateTime checklistDate;
    try {
      checklistDate = DateTime.parse(
        json['checklistDate']?.toString() ?? DateTime.now().toString(),
      );
    } catch (e) {
      print('⚠️ Error parsing checklistDate: $e');
      checklistDate = DateTime.now();
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toString(),
      );
    } catch (e) {
      print('⚠️ Error parsing createdAt: $e');
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    try {
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt']!.toString());
      }
    } catch (e) {
      print('⚠️ Error parsing updatedAt: $e');
      updatedAt = null;
    }

    return ChecklistResponse(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleRegNo: json['vehicleRegNo']?.toString() ?? '',
      checklistDate: checklistDate,
      checkedBy: checkedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      responses: responses,
      isSubmitted: json['isSubmitted'] ?? false,
      status: json['status']?.toString(),
      approvedBy: approvedBy,
    );
  }

  // Helper getters for backward compatibility
  String get checkedById => checkedBy.id;
  String get checkedByName => checkedBy.name;
  String get checkedByRole => checkedBy.role;

  String? get approvedById => approvedBy?.id;
  String? get approvedByName => approvedBy?.name;
  String? get approvedByRole => approvedBy?.role;

  String getStatusText() {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status?.toUpperCase() ?? '';
    }
  }

  Color getStatusColor() {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatCheckedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkedDay = DateTime(
      checklistDate.year,
      checklistDate.month,
      checklistDate.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (checkedDay == today) {
      return 'Today ${_formatTimeOnly(checklistDate)}';
    } else if (checkedDay == yesterday) {
      return 'Yesterday ${_formatTimeOnly(checklistDate)}';
    } else {
      return '${checklistDate.day}/${checklistDate.month}/${checklistDate.year} ${_formatTimeOnly(checklistDate)}';
    }
  }

  String _formatTimeOnly(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }
  
}

class CheckedBy {
  final String id;
  final String name;
  final String role;

  CheckedBy({required this.id, required this.name, required this.role});

  factory CheckedBy.fromJson(Map<String, dynamic> json) {
    try {
      return CheckedBy(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error in CheckedBy.fromJson: $e');
      print('❌ JSON: $json');
      return CheckedBy(id: '', name: '', role: '');
    }
  }
  
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role};
  }
}

class ChecklistItemResponse {
  final String? status; // "good" or "bad"
  final String? remarks;

  ChecklistItemResponse({this.status, this.remarks});

  factory ChecklistItemResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistItemResponse(
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'remarks': remarks};
  }
}

class ChecklistSubmitRequest {
  final int vehicleId;
  final String vehicleRegNo;
  final String checklistDate;
  final int checkedById;
  final Map<String, ChecklistItemRequest> responses;

  ChecklistSubmitRequest({
    required this.vehicleId,
    required this.vehicleRegNo,
    required this.checklistDate,
    required this.checkedById,
    required this.responses,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicleRegNo': vehicleRegNo,
      'checklistDate': checklistDate,
      'checkedById': checkedById,
      'responses': responses.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class ChecklistItemRequest {
  final String status; // "good" or "bad"
  final String? remarks;

  ChecklistItemRequest({required this.status, this.remarks});

  Map<String, dynamic> toJson() {
    return {'status': status, 'remarks': remarks ?? ''};
  }
}