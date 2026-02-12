import 'dart:convert';

import 'package:flutter/material.dart';

class TripCardListRequest {
  final String timeFilter; // today, week, month, all
  final String? statusFilter; // pending, approved, completed, ongoing, all
  final int page;
  final int limit;

  TripCardListRequest({
    required this.timeFilter,
    this.statusFilter,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'timeFilter': timeFilter,
      'statusFilter': statusFilter,
      'page': page,
      'limit': limit,
    };
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
  final String requesterName;
  final String? vehicleModel;
  final String? vehicleRegNo;
  final String status;
  final DateTime date;
  final String time;
  final String? startLocation;
  final String? endLocation;
  final List<int>? conflictingTripIds;
  final int passengerCount;
  final String? purpose;
  final String driverAssignment; // primary, secondary, none
  final bool isPrimaryDriver;
  final String odometerStatus; // complete, start_only, none
  final Map<String, dynamic>? odometerLog;
  final bool? isScheduled;
  final bool? isInstance;

  TripCardModel({
    required this.id,
    required this.requesterName,
    this.vehicleModel,
    this.vehicleRegNo,
    required this.status,
    required this.date,
    required this.time,
    this.startLocation,
    this.endLocation,
    this.conflictingTripIds,
    required this.passengerCount,
    this.purpose,
    required this.driverAssignment,
    required this.isPrimaryDriver,
    required this.odometerStatus,
    this.odometerLog,
    this.isScheduled,
    this.isInstance,
  });

  factory TripCardModel.fromJson(Map<String, dynamic> json) {
    return TripCardModel(
      id: json['id'],
      requesterName: json['requesterName'] ?? 'Unknown',
      vehicleModel: json['vehicleModel'] ?? 'Unknown',
      vehicleRegNo: json['vehicleRegNo'] ?? 'Unknown',
      status: json['status'],
      date: DateTime.parse(json['startDate']),
      time: json['startTime'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      conflictingTripIds: json['conflictingTripIds'] != null
          ? List<int>.from(json['conflictingTripIds'])
          : null,
      passengerCount: json['passengerCount'] ?? 1,
      purpose: json['purpose'],
      driverAssignment: json['driverAssignment'] ?? 'none',
      isPrimaryDriver: json['isPrimaryDriver'] ?? false,
      odometerStatus: json['odometerStatus'] ?? 'none',
      odometerLog: json['odometerLog'] != null
          ? Map<String, dynamic>.from(json['odometerLog'])
          : null,
      isScheduled: json['isScheduled'] ?? false,
      isInstance: json['isInstance'] ?? false,
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
}
