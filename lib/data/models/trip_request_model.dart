import 'package:flutter/material.dart';

class TripRequest {
  final Map<String, dynamic> locationData;
  final Map<String, dynamic> scheduleData;
  final Map<String, dynamic> passengerData;
  final int? selectedVehicleId;
  final int? conflictingTripId;

  TripRequest({
    required this.locationData,
    required this.scheduleData,
    required this.passengerData,
    this.selectedVehicleId,
    this.conflictingTripId,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'locationData': _convertToJson(locationData),
      'scheduleData': _convertToJson(scheduleData),
      'passengerData': _convertToJson(passengerData),
    };
    
    // Only include vehicleId if it's not null
    if (selectedVehicleId != null) {
      json['vehicleId'] = selectedVehicleId;
    }

    if (conflictingTripId != null) {
      json['conflictingTripId'] = conflictingTripId; // Include in JSON
    }
    
    return json;
  }

  // Helper method to convert DateTime objects to ISO strings
  static dynamic _convertToJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) {
        return MapEntry(key, _convertToJson(value));
      });
    } else if (data is List) {
      return data.map((item) => _convertToJson(item)).toList();
    } else if (data is DateTime) {
      return data.toIso8601String(); // Convert DateTime to ISO string
    } else if (data is TimeOfDay) {
      return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}'; // Convert TimeOfDay to string
    }
    return data;
  }
}
