import 'dart:convert';

import 'package:flutter/material.dart';

class TripCardListRequest {
  final String timeFilter; // today, week, month, all
  final String? statusFilter; // pending, approved, completed, ongoing, all
  final String? searchQuery;
  final String? sortField; 
  final String? sortOrder;
  final int page;
  final int limit;

  TripCardListRequest({
    required this.timeFilter,
    this.statusFilter,
    this.searchQuery,
    this.sortField,
    this.sortOrder,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'page': page, 'limit': limit};

    if (timeFilter != null) map['timeFilter'] = timeFilter;
    if (statusFilter != null) map['statusFilter'] = statusFilter;
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      map['search'] = searchQuery; // or 'searchQuery' depending on your API
    }
    if (sortField != null) map['sortField'] = sortField; // 'id' or 'startTime'
    if (sortOrder != null) map['sortOrder'] = sortOrder; // 'asc' or 'desc'

    return map;
  }

}

class TripCardResponse {
  final bool success;
  final TripCardData data;
  final int statusCode;

  TripCardResponse({
    required this.success,
    required this.data,
    required this.statusCode,
  });

  factory TripCardResponse.fromJson(Map<String, dynamic> json) {
    return TripCardResponse(
      success: json['success'],
      data: TripCardData.fromJson(json['data']),
      statusCode: json['statusCode'],
    );
  }
}

class TripCardData {
  final List<TripCardModel> trips;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  TripCardData({
    required this.trips,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory TripCardData.fromJson(Map<String, dynamic> json) {
    return TripCardData(
      trips: (json['trips'] as List)
          .map((trip) => TripCardModel.fromJson(trip))
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      hasMore: json['hasMore'],
    );
  }
}

class TripCardModel {
  final int id;
  final String status;
  final DateTime date;
  final String time;
  final String? requesterName;
  final String? tripUserType;
  final String? vehicleModel;
  final String? vehicleRegNo;
  final String? startLocation;
  final String? endLocation;
  final List<int>? conflictingTripIds;
  final List<int>? connectedTripIds;
  final int? passengerCount;
  final String? purpose;
  final String? driverAssignment; // primary, secondary, none
  final bool? isPrimaryDriver;
  final String? odometerStatus; // complete, start_only, none
  final Map<String, dynamic>? odometerLog;
  final DateTime? createdAt;
  final DateTime? confirmAt;

  final OdometerReading? odometerReading;

  final DriverDetails? driver;

  // NEW FIELDS FOR SCHEDULED TRIPS
  final bool? isScheduled;
  final bool? isInstance;
  final int? masterTripId;
  final int? instanceCount;
  final List<int>? instanceIds;

  TripCardModel({
    required this.id,
    required this.status,
    required this.date,
    required this.time,
    this.requesterName,
    this.tripUserType,
    this.vehicleModel,
    this.vehicleRegNo,
    this.startLocation,
    this.endLocation,
    this.conflictingTripIds,
    this.connectedTripIds,
    this.passengerCount,
    this.purpose,
    this.driverAssignment,
    this.isPrimaryDriver,
    this.odometerStatus,
    this.odometerLog,
    this.createdAt,
    this.confirmAt,
    this.isScheduled,
    this.isInstance,
    this.masterTripId,
    this.instanceCount,
    this.instanceIds,

    this.odometerReading,

    this.driver,
  });

  factory TripCardModel.fromJson(Map<String, dynamic> json) {

    final dateStr = json['date'] ?? json['startDate'] ?? DateTime.now();

    return TripCardModel(
      id: json['id'],
      requesterName: json['requesterName'] ?? 'Unknown',
      tripUserType: json['tripUserType'] ?? 'R',
      vehicleModel: json['vehicleModel'] ?? 'Unknown',
      vehicleRegNo: json['vehicleRegNo'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      date: DateTime.parse(dateStr),
      time: json['startTime'] ?? json['time'] ?? '00:00',
      startLocation: json['startLocation'] ?? 'Unknown',
      endLocation: json['endLocation'] ?? 'Unknown',
      conflictingTripIds: json['conflictingTripIds'] != null
          ? List<int>.from(json['conflictingTripIds'])
          : null,
      connectedTripIds: json['connectedTripIds'] != null
          ? List<int>.from(json['connectedTripIds'])
          : null,
      passengerCount: json['passengerCount'] ?? 1,
      purpose: json['purpose'],
      driverAssignment: json['driverAssignment'] ?? 'none',
      isPrimaryDriver: json['isPrimaryDriver'] ?? false,
      odometerStatus: json['odometerStatus'] ?? 'none',
      odometerLog: json['odometerLog'] != null
          ? Map<String, dynamic>.from(json['odometerLog'])
          : null,
      createdAt: _parseDate(json['createdAt']),
      confirmAt: _parseDate(json['confirmAt']),
      isScheduled: json['isScheduled'] ?? false,
      isInstance: json['isInstance'] ?? false,
      masterTripId: json['masterTripId'],
      instanceCount: json['instanceCount'] ?? 0,
      instanceIds: json['instanceIds'] != null
          ? List<int>.from(json['instanceIds'])
          : null,

      odometerReading: json['odometerReading'] != null
          ? OdometerReading.fromJson(json['odometerReading'])
          : null,

      driver: json['driver'] != null
          ? DriverDetails.fromJson(json['driver'])
          : null,
    );
  }

  
  static DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      debugPrint('Error parsing date: $dateString - $e');
      return null;
    }
  }
}

class OdometerReading {
  final double? startReading;
  final double? endReading;
  final DateTime? startRecordedAt;
  final DateTime? endRecordedAt;
  final String? startRecordedBy;
  final String? endRecordedBy;

  OdometerReading({
    this.startReading,
    this.endReading,
    this.startRecordedAt,
    this.endRecordedAt,
    this.startRecordedBy,
    this.endRecordedBy,
  });

  factory OdometerReading.fromJson(Map<String, dynamic> json) {
    double? parseReading(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    String? parseRecordedBy(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map<String, dynamic>) return value['name']?.toString();
      return null;
    }

    return OdometerReading(
      startReading: parseReading(json['startReading']),
      endReading: parseReading(json['endReading']),
      startRecordedAt: parseDateTime(json['startRecordedAt']),
      endRecordedAt: parseDateTime(json['endRecordedAt']),
      startRecordedBy: parseRecordedBy(json['startRecordedBy']),
      endRecordedBy: parseRecordedBy(json['endRecordedBy']),
    );
  }
}

class DriverDetails {
  final int id;
  final String name;
  final String? phone;
  final String? role;

  DriverDetails({required this.id, required this.name, this.phone, this.role});

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Not Assigned',
      phone: json['phone'],
      role: json['role'],
    );
  }
}

// Extension for common formatting methods
extension TripCardModelExtension on TripCardModel {
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.grey[700]!;
      case 'canceled':
        return Colors.red;
      case 'rejected':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  String formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String formatTime() {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      hour = hour == 0 ? 12 : hour;
      final minuteStr = minute.toString().padLeft(2, '0');

      return '$hour:$minuteStr $period';
    } catch (e) {
      return time;
    }
  }

  String formatCreatedAt() {
    if (createdAt == null) return 'Not available';

    final now = DateTime.now();
    final created = createdAt!;
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(created.year, created.month, created.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (createdDay == today) {
      return 'Created: Today ${_formatTimeOnly(created)}';
    } else if (createdDay == yesterday) {
      return 'Created: Yesterday ${_formatTimeOnly(created)}';
    } else {
      return 'Created: ${created.day}/${created.month}/${created.year} ${_formatTimeOnly(created)}';
    }
  }

  String formatConfirmAt() {
    if (confirmAt == null) return 'Not confirmed';

    final now = DateTime.now();
    final confirmed = confirmAt!;
    final today = DateTime(now.year, now.month, now.day);
    final confirmedDay = DateTime(
      confirmed.year,
      confirmed.month,
      confirmed.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (confirmedDay == today) {
      return 'Confirmed: Today ${_formatTimeOnly(confirmed)}';
    } else if (confirmedDay == yesterday) {
      return 'Confirmed: Yesterday ${_formatTimeOnly(confirmed)}';
    } else {
      return 'Confirmed: ${confirmed.day}/${confirmed.month}/${confirmed.year} ${_formatTimeOnly(confirmed)}';
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

  IconData getTimelineIcon() {
    if (createdAt != null && confirmAt == null) {
      return Icons.access_time; // Created but not confirmed
    } else if (createdAt != null && confirmAt != null) {
      return Icons.check_circle; // Created and confirmed
    } else {
      return Icons.help_outline; // Unknown
    }
  }

  Color getTimelineColor() {
    if (createdAt != null && confirmAt == null) {
      return Colors.orange; // Created but not confirmed
    } else if (createdAt != null && confirmAt != null) {
      return Colors.green; // Created and confirmed
    } else {
      return Colors.grey; // Unknown
    }
  }
}
