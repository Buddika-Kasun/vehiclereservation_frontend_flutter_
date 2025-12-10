import 'dart:convert';

class DriverTripResponse {
  final bool success;
  final DriverTripData data;
  final int statusCode;

  DriverTripResponse({
    required this.success,
    required this.data,
    required this.statusCode,
  });

  factory DriverTripResponse.fromJson(Map<String, dynamic> json) {
    return DriverTripResponse(
      success: json['success'],
      data: DriverTripData.fromJson(json['data']),
      statusCode: json['statusCode'],
    );
  }
}

class DriverTripData {
  final List<DriverTripCard> trips;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  DriverTripData({
    required this.trips,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory DriverTripData.fromJson(Map<String, dynamic> json) {
    return DriverTripData(
      trips: (json['trips'] as List)
          .map((trip) => DriverTripCard.fromJson(trip))
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      hasMore: json['hasMore'],
    );
  }
}

class DriverTripCard {
  final int id;
  final String vehicleModel;
  final String vehicleRegNo;
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

  DriverTripCard({
    required this.id,
    required this.vehicleModel,
    required this.vehicleRegNo,
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
  });

  factory DriverTripCard.fromJson(Map<String, dynamic> json) {
    return DriverTripCard(
      id: json['id'],
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
    );
  }
}


class DriverTripListRequest {
  final String timeFilter; // today, week, month, all
  final String? statusFilter; // pending, approved, completed, ongoing, all
  final int page;
  final int limit;

  DriverTripListRequest({
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
