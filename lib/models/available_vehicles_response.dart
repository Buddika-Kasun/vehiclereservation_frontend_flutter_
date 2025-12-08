import 'package:vehiclereservation_frontend_flutter_/models/vehicle_model.dart';

class AvailableVehiclesResponse {
  final List<AvailableVehicle> recommendedVehicles;
  final List<AvailableVehicle> allVehicles;
  final List<dynamic> conflictingTrips;
  final bool canBookNew;

  AvailableVehiclesResponse({
    required this.recommendedVehicles,
    required this.allVehicles,
    required this.conflictingTrips,
    required this.canBookNew,
  });

  factory AvailableVehiclesResponse.fromJson(Map<String, dynamic> json) {
    print('Parsing AvailableVehiclesResponse from: $json');
    
    try {
      // Handle different response structures
      final recommendedVehiclesData = json['recommendedVehicles'] as List<dynamic>? ?? [];
      final allVehiclesData = json['allVehicles'] as List<dynamic>? ?? [];
      
      print('Found ${recommendedVehiclesData.length} recommended vehicles');
      print('Found ${allVehiclesData.length} all vehicles');

      final response = AvailableVehiclesResponse(
        recommendedVehicles: recommendedVehiclesData
            .map((vehicle) => AvailableVehicle.fromJson(vehicle))
            .toList(),
        allVehicles: allVehiclesData
            .map((vehicle) => AvailableVehicle.fromJson(vehicle))
            .toList(),
        conflictingTrips: json['conflictingTrips'] ?? [],
        canBookNew: json['canBookNew'] ?? false,
      );
      
      print('Successfully parsed response with ${response.recommendedVehicles.length} recommended and ${response.allVehicles.length} all vehicles');
      return response;
    } catch (e) {
      print('Error parsing AvailableVehiclesResponse: $e');
      print('JSON that caused error: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'recommendedVehicles': recommendedVehicles.map((v) => v.toJson()).toList(),
      'allVehicles': allVehicles.map((v) => v.toJson()).toList(),
      'conflictingTrips': conflictingTrips,
      'canBookNew': canBookNew,
    };
  }
}

class AvailableVehicle {
  final Vehicle vehicle;
  final bool isRecommended;
  final String recommendationReason;
  final double distanceFromStart;
  final double estimatedArrivalTime;
  final bool isInConflict;
  final ConflictTripData? conflictingTripData;

  AvailableVehicle({
    required this.vehicle,
    required this.isRecommended,
    required this.recommendationReason,
    required this.distanceFromStart,
    required this.estimatedArrivalTime,
    required this.isInConflict,
    this.conflictingTripData,    
  });

  factory AvailableVehicle.fromJson(Map<String, dynamic> json) {
    print('Parsing AvailableVehicle from: $json');
    
    try {
      // Handle vehicle data - it might be nested under 'vehicle' key or be the direct object
      final vehicleData = json['vehicle'] ?? json;
      
      final availableVehicle = AvailableVehicle(
        vehicle: Vehicle.fromJson(vehicleData),
        isRecommended: json['isRecommended'] ?? false,
        recommendationReason: json['recommendationReason']?.toString() ?? '',
        distanceFromStart: _parseDouble(json['distanceFromStart']),
        estimatedArrivalTime: _parseDouble(json['estimatedArrivalTime']),
        isInConflict: json['isInConflict']?? false,
        conflictingTripData: json['conflictingTripData'] != null 
          ? ConflictTripData.fromJson(json['conflictingTripData'])
          : null,
      );
      
      print('Successfully parsed AvailableVehicle: ${availableVehicle.vehicle.regNo}');
      return availableVehicle;
    } catch (e) {
      print('Error parsing AvailableVehicle: $e');
      print('JSON that caused error: $json');
      rethrow;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle': vehicle.toJson(),
      'isRecommended': isRecommended,
      'recommendationReason': recommendationReason,
      'distanceFromStart': distanceFromStart,
      'estimatedArrivalTime': estimatedArrivalTime,
    };
  }
}

class ConflictTripData {
  final int tripId;
  final String startTime;
  final ConflictLocation startLocation;
  final ConflictLocation endLocation;

  ConflictTripData({
    required this.tripId,
    required this.startTime,
    required this.startLocation,
    required this.endLocation,
  });

  factory ConflictTripData.fromJson(Map<String, dynamic> json) {
    return ConflictTripData(
      tripId: json['tripId'] as int,
      startTime: json['startTime'] as String,
      startLocation: ConflictLocation.fromJson(json['startLocation']),
      endLocation: ConflictLocation.fromJson(json['endLocation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'startTime': startTime,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
    };
  }
}

class ConflictLocation {
  final String address;
  final String latitude;
  final String longitude;

  ConflictLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory ConflictLocation.fromJson(Map<String, dynamic> json) {
    return ConflictLocation(
      address: json['address'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}