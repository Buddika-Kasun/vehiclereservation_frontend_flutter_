class VehicleType {
  final int id;
  final String vehicleType;
  final double costPerKm;
  final DateTime validFrom;
  final bool isActive;
  final String? vehicleCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleType({
    required this.id,
    required this.vehicleType,
    required this.costPerKm,
    required this.validFrom,
    required this.isActive,
    this.vehicleCount,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] ?? json['_id'] ?? 0,
      vehicleType: json['type'] ?? json['vehicleType'] ?? '',
      costPerKm: _parseDouble(json['costPerKm'] ?? json['cost_per_km'] ?? 0.0),
      validFrom: _parseDateTime(json['validFrom'] ?? json['valid_from']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      vehicleCount: json['vehicleCount']?.toString() ?? json['vehicle_count']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    try {
      return DateTime.parse(dateTime);
    } catch (e) {
      // If parsing fails, return current date in UTC
      return DateTime.now().toUtc();
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {

    return {
      'vehicleType': vehicleType,
      'costPerKm': costPerKm,
      'validFrom': validFrom.toIso8601String(),
      'isActive': isActive,
    };
  }
}
