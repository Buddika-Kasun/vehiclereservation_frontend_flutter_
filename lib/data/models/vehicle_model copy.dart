class Vehicle {
  final int id;
  final String regNo;
  final String? model;
  final String? fuelType;
  final int seatingCapacity;
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
