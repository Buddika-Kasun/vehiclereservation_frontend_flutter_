class Vehicle {
  final int id;
  final String regNo;
  final String? model;
  final String? fuelType;
  final int seatingCapacity;
  final int? seatingAvailability;
  final String? vehicleImage;
  final String? qrCode;
  final double odometerLastReading;
  final Map<String, dynamic>? dailyInspectionChecklist;
  final int? vehicleTypeId;
  final String? vehicleType;
  final int? assignedDriverPrimaryId;
  final String? assignedDriverPrimaryName;
  final int? assignedDriverSecondaryId;
  final String? assignedDriverSecondaryName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vehicle({
    required this.id,
    required this.regNo,
    this.model,
    this.fuelType,
    this.seatingCapacity = 4,
    this.seatingAvailability,
    this.vehicleImage,
    this.qrCode,
    this.odometerLastReading = 0.0,
    this.dailyInspectionChecklist,
    this.vehicleTypeId,
    this.vehicleType,
    this.assignedDriverPrimaryId,
    this.assignedDriverPrimaryName,
    this.assignedDriverSecondaryId,
    this.assignedDriverSecondaryName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      regNo: json['regNo'] ?? '',
      model: json['model'],
      fuelType: json['fuelType'],
      seatingCapacity: json['seatingCapacity'] ?? 4,
      seatingAvailability: json['seatingAvailability'] ?? 4,
      vehicleImage: json['vehicleImage'] ?? json['vehicle_image'],
      qrCode: json['qrCode'],
      odometerLastReading: _parseDouble(json['odometerLastReading'] ?? 0.0),
      dailyInspectionChecklist: json['dailyInspectionChecklist'] ?? json['daily_inspection_checklist'],
      vehicleTypeId: json['vehicleType']?['id'],
      vehicleType: json['vehicleType']?['vehicleType'],
      assignedDriverPrimaryId: json['assignedDriverPrimary']?['id'],
      assignedDriverPrimaryName: json['assignedDriverPrimary']?['displayname'],
      assignedDriverSecondaryId: json['assignedDriverSecondary']?['id'],
      assignedDriverSecondaryName: json['assignedDriverSecondary']?['displayname'],
      isActive: json['isActive']?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
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
      'regNo': regNo,
      'model': model,
      'fuelType': fuelType,
      'seatingCapacity': seatingCapacity,
      'vehicleImage': vehicleImage,
      'odometerLastReading': odometerLastReading,
      'dailyInspectionChecklist': dailyInspectionChecklist,
      'vehicleTypeId': vehicleTypeId,
      'assignedDriverPrimaryId': assignedDriverPrimaryId,
      'assignedDriverSecondaryId': assignedDriverSecondaryId,
      'isActive': isActive,
    };
  }
}

class AvailableVehicle {
  final Vehicle vehicle;
  final bool isRecommended;
  final String recommendationReason;
  final double distanceFromStart;
  final double estimatedArrivalTime;

  AvailableVehicle({
    required this.vehicle,
    required this.isRecommended,
    required this.recommendationReason,
    required this.distanceFromStart,
    required this.estimatedArrivalTime,
  });

  factory AvailableVehicle.fromJson(Map<String, dynamic> json) {
    return AvailableVehicle(
      vehicle: Vehicle.fromJson(json['vehicle']),
      isRecommended: json['isRecommended'] ?? false,
      recommendationReason: json['recommendationReason'] ?? '',
      distanceFromStart: _parseDouble(json['distanceFromStart'] ?? 0),
      estimatedArrivalTime: _parseDouble(json['estimatedArrivalTime'] ?? 0),
    );
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
    // Handle both direct response and nested data structure
    final data = json['data'] ?? json;
    
    return AvailableVehiclesResponse(
      recommendedVehicles: (data['recommendedVehicles'] as List<dynamic>? ?? [])
          .map((vehicle) => AvailableVehicle.fromJson(vehicle))
          .toList(),
      allVehicles: (data['allVehicles'] as List<dynamic>? ?? [])
          .map((vehicle) => AvailableVehicle.fromJson(vehicle))
          .toList(),
      conflictingTrips: data['conflictingTrips'] ?? [],
      canBookNew: data['canBookNew'] ?? false,
    );
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

class VehicleLocation {
  final int vehicleId;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;

  VehicleLocation({
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> json) {
    return VehicleLocation(
      vehicleId: json['vehicleId'] ?? 0,
      latitude: _parseDouble(json['latitude'] ?? 0.0),
      longitude: _parseDouble(json['longitude'] ?? 0.0),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
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
      'vehicleId': vehicleId,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}