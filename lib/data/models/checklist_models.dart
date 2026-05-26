// models/checklist_models.dart

import 'package:flutter/material.dart';

class ChecklistResponse {
  final String id;
  final String vehicleId;
  final String vehicleRegNo;
  final DateTime checklistDate;
  final CheckedBy checkedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, ChecklistItemResponse> responses;
  final bool isSubmitted;
  final String? status;
  final CheckedBy? approvedBy;
  final String? comment;

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
    this.comment,
  });

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    // Parse checkedBy
    CheckedBy checkedBy = CheckedBy(id: '', name: '', role: '');
    try {
      if (json['checkedBy'] != null && json['checkedBy'] is Map) {
        checkedBy = CheckedBy.fromJson(
          Map<String, dynamic>.from(json['checkedBy']),
        );
      }
    } catch (e) {
      print('Error parsing checkedBy: $e');
    }

    // Parse approvedBy
    CheckedBy? approvedBy;
    try {
      if (json['approvedBy'] != null && json['approvedBy'] is Map) {
        approvedBy = CheckedBy.fromJson(
          Map<String, dynamic>.from(json['approvedBy']),
        );
      }
    } catch (e) {
      print('Error parsing approvedBy: $e');
    }

    // Parse responses
    Map<String, ChecklistItemResponse> responses = {};
    try {
      if (json['responses'] != null && json['responses'] is Map) {
        final responsesMap = Map<String, dynamic>.from(json['responses']);
        responses = responsesMap.map((key, value) {
          try {
            if (value is Map) {
              return MapEntry(
                key,
                ChecklistItemResponse.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              );
            }
          } catch (e) {
            print('Error parsing response $key: $e');
          }
          return MapEntry(
            key,
            ChecklistItemResponse(status: null, remarks: null),
          );
        });
      }
    } catch (e) {
      print('Error parsing responses: $e');
    }

    // Parse dates
    DateTime checklistDate = DateTime.now();
    try {
      if (json['checklistDate'] != null) {
        checklistDate = DateTime.parse(json['checklistDate'].toString());
      }
    } catch (e) {
      print('Error parsing checklistDate: $e');
    }

    DateTime createdAt = DateTime.now();
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt'].toString());
      }
    } catch (e) {
      print('Error parsing createdAt: $e');
    }

    DateTime? updatedAt;
    try {
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt'].toString());
      }
    } catch (e) {
      print('Error parsing updatedAt: $e');
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
      comment: json['comment']?.toString(),
    );
  }

  String getStatusText() {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status?.toUpperCase() ?? 'UNKNOWN';
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
    final sriLankanDate = _toSriLankanTime(checklistDate);
    final sriLankanCreatedAt = _toSriLankanTime(createdAt);
    final now = _toSriLankanTime(DateTime.now());

    final today = DateTime(now.year, now.month, now.day);
    final checkedDay = DateTime(
      sriLankanDate.year,
      sriLankanDate.month,
      sriLankanDate.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (checkedDay == today) {
      return 'Today ${_formatTimeOnly(sriLankanCreatedAt)}';
    } else if (checkedDay == yesterday) {
      return 'Yesterday ${_formatTimeOnly(sriLankanCreatedAt)}';
    } else {
      return '${sriLankanDate.day}/${sriLankanDate.month}/${sriLankanDate.year} ${_formatTimeOnly(sriLankanCreatedAt)}';
    }
  }

  DateTime _toSriLankanTime(DateTime utcTime) {
    const sriLankanOffset = Duration(hours: 5, minutes: 30);
    return utcTime.add(sriLankanOffset);
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

class VehicleChecklistResponse {
  final String id;
  final String vehicleId;
  final String vehicleRegNo;
  final DateTime? checklistDate;
  final CheckedBy? checkedBy;
  final DateTime? createdAt;
  final bool isSubmitted;
  final String? status;

  VehicleChecklistResponse({
    required this.id,
    required this.vehicleId,
    required this.vehicleRegNo,
    this.checklistDate,
    this.checkedBy,
    this.createdAt,
    required this.isSubmitted,
    this.status,
  });

  factory VehicleChecklistResponse.fromJson(Map<String, dynamic> json) {
    // Parse checkedBy
    CheckedBy checkedBy = CheckedBy(id: '', name: '', role: '');
    try {
      if (json['checkedBy'] != null && json['checkedBy'] is Map) {
        checkedBy = CheckedBy.fromJson(
          Map<String, dynamic>.from(json['checkedBy']),
        );
      }
    } catch (e) {
      print('Error parsing checkedBy: $e');
    }

    // Parse dates
    DateTime checklistDate = DateTime.now();
    try {
      if (json['checklistDate'] != null) {
        checklistDate = DateTime.parse(json['checklistDate'].toString());
      }
    } catch (e) {
      print('Error parsing checklistDate: $e');
    }

    DateTime createdAt = DateTime.now();
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt'].toString());
      }
    } catch (e) {
      print('Error parsing createdAt: $e');
    }

    return VehicleChecklistResponse(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleRegNo: json['vehicleRegNo']?.toString() ?? '',
      checklistDate: checklistDate,
      checkedBy: checkedBy,
      createdAt: createdAt,
      isSubmitted: json['isSubmitted'],
      status: json['status']?.toString(),
    );
  }

  String getStatusText() {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return 'REVIEW';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status?.toUpperCase() ?? 'UNKNOWN';
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
    final sriLankanDate = _toSriLankanTime(checklistDate!);
    final sriLankanCreatedAt = _toSriLankanTime(createdAt!);
    final now = _toSriLankanTime(DateTime.now());

    final today = DateTime(now.year, now.month, now.day);
    final checkedDay = DateTime(
      sriLankanDate.year,
      sriLankanDate.month,
      sriLankanDate.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (checkedDay == today) {
      return 'Today ${_formatTimeOnly(sriLankanCreatedAt)}';
    } else if (checkedDay == yesterday) {
      return 'Yesterday ${_formatTimeOnly(sriLankanCreatedAt)}';
    } else {
      return '${sriLankanDate.day}/${sriLankanDate.month}/${sriLankanDate.year} ${_formatTimeOnly(sriLankanCreatedAt)}';
    }
  }

  DateTime _toSriLankanTime(DateTime utcTime) {
    const sriLankanOffset = Duration(hours: 5, minutes: 30);
    return utcTime.add(sriLankanOffset);
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
    return CheckedBy(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role};
  }
}

class ChecklistItemResponse {
  final String? status;
  final String? remarks;

  ChecklistItemResponse({this.status, this.remarks});

  factory ChecklistItemResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistItemResponse(
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
    );
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

class ChecklistApiResponse {
  final List<ChecklistResponse> checklists;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  ChecklistApiResponse({
    required this.checklists,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory ChecklistApiResponse.fromJson(Map<String, dynamic> json) {
    List<ChecklistResponse> checklists = [];

    if (json['checklists'] != null) {
      checklists = (json['checklists'] as List)
          .map(
            (item) => ChecklistResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else if (json['data'] != null && json['data']['checklists'] != null) {
      checklists = (json['data']['checklists'] as List)
          .map(
            (item) => ChecklistResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return ChecklistApiResponse(
      checklists: checklists,
      total: json['total'] ?? checklists.length,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class VehicleChecklistApiResponse {
  final List<VehicleChecklistResponse> checklists;
  final int total;
  final int totalChecklists;
  final int page;
  final int limit;
  final bool hasMore;

  VehicleChecklistApiResponse({
    required this.checklists,
    required this.total,
    required this.totalChecklists,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory VehicleChecklistApiResponse.fromJson(Map<String, dynamic> json) {
    List<VehicleChecklistResponse> checklists = [];

    if (json['checklists'] != null) {
      checklists = (json['checklists'] as List)
          .map(
            (item) => VehicleChecklistResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else if (json['data'] != null && json['data']['checklists'] != null) {
      checklists = (json['data']['checklists'] as List)
          .map(
            (item) => VehicleChecklistResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return VehicleChecklistApiResponse(
      checklists: checklists,
      total: json['total'] ?? checklists.length,
      totalChecklists: json['totalChecklists'],
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasMore: json['hasMore'] ?? false,
    );
  }
}
