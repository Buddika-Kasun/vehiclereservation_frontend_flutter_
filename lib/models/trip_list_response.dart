import 'dart:convert';

import 'package:flutter/material.dart';

class TripListResponse {
  final List<TripCard> trips;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  TripListResponse({
    required this.trips,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory TripListResponse.fromJson(Map<String, dynamic> json) {
    return TripListResponse(
      trips: (json['trips'] as List)
          .map((trip) => TripCard.fromJson(trip))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class TripCard {
  final int id;
  final String vehicleModel;
  final String vehicleRegNo;
  final String status;
  final DateTime date;
  final String time;
  final String tripType; // R, RO, P, J
  final String? driverName;
  final String? startLocation;
  final String? endLocation;

  TripCard({
    required this.id,
    required this.vehicleModel,
    required this.vehicleRegNo,
    required this.status,
    required this.date,
    required this.time,
    required this.tripType,
    this.driverName,
    this.startLocation,
    this.endLocation,
  });

  factory TripCard.fromJson(Map<String, dynamic> json) {
    return TripCard(
      id: json['id'] ?? 0,
      vehicleModel: json['vehicleModel'] ?? 'Unknown',
      vehicleRegNo: json['vehicleRegNo'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      time: json['time'] ?? '00:00',
      tripType: json['tripType'] ?? 'R',
      driverName: json['driverName'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
    );
  }

  // Helper method to get trip type label
  String get tripTypeLabel {
    switch (tripType) {
      case 'R': return 'R';
      case 'RO': return 'RO';
      case 'P': return 'P';
      case 'J': return 'J';
      default: return 'R';
    }
  }

  String get tripTypeFullText {
    switch (tripType) {
      case 'R': return 'Created and going';
      case 'RO': return 'Created for others';
      case 'P': return 'Passenger in trip';
      case 'J': return 'Joined trip';
      default: return 'Created trip';
    }
  }

  Color get tripTypeColor {
    switch (tripType) {
      case 'R': return Colors.blue;
      case 'RO': return Colors.purple;
      case 'P': return Colors.green;
      case 'J': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

enum TimeFilter {
  today,
  week,
  month,
  all,
}

enum TripStatus {
  draft,
  pending,
  approved,
  rejected,
  ongoing,
  completed,
  canceled,
}

// Trip list request model
class TripListRequest {
  final TimeFilter timeFilter; // today, week, month, all
  final TripStatus? statusFilter;
  final int page;
  final int limit;

  TripListRequest({
    required this.timeFilter,
    this.statusFilter,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'timeFilter': timeFilter.name,
      'page': page,
      'limit': limit,
    };
    
    if (statusFilter != null) {
      json['statusFilter'] = statusFilter!.name;
    }
    
    return json;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}