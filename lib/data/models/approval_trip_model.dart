class ApprovalTrip {
  final int id;
  final String status;
  final DateTime startDate;
  final String startTime;
  final Vehicle? vehicle;
  final List<int>? conflictingTripIds;
  final OdometerReading? odometerReading;
  final DriverInfo? driver;

  ApprovalTrip({
    required this.id,
    required this.status,
    required this.startDate,
    required this.startTime,
    this.vehicle,
    this.conflictingTripIds,
    this.odometerReading,
    this.driver,
  });

  factory ApprovalTrip.fromJson(Map<String, dynamic> json) {
    return ApprovalTrip(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'approved',
      startDate: DateTime.parse(json['startDate']),
      startTime: json['startTime'] ?? '',
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'])
          : null,
      conflictingTripIds: json['conflictingTripIds'] != null
          ? List<int>.from(json['conflictingTripIds'])
          : null,
      odometerReading: json['odometerReading'] != null
          ? OdometerReading.fromJson(json['odometerReading'])
          : null,
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'])
          : null,
    );
  }

  // Check if trip has start reading recorded
  bool get hasStartReading => odometerReading?.startReading != null;

  // Check if trip has end reading recorded
  bool get hasEndReading => odometerReading?.endReading != null;

  // Check if trip is fully read (both start and end readings)
  bool get isFullyRead => hasStartReading && hasEndReading;

  // Check if trip needs start reading
  bool get needsStartReading => !hasStartReading;

  // Check if trip needs end reading
  bool get needsEndReading => hasStartReading && !hasEndReading;

  // Get current reading type needed
  String? get readingTypeNeeded {
    if (needsStartReading) return 'start';
    if (needsEndReading) return 'end';
    return null;
  }
}

class DriverInfo {
  final int id;
  final String name;
  final String? phone;
  final String? role;

  DriverInfo({required this.id, required this.name, this.phone, this.role});

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Not Assigned',
      phone: json['phone'],
      role: json['role'],
    );
  }
}

class Vehicle {
  final String model;
  final String registrationNumber;

  Vehicle({required this.model, required this.registrationNumber});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      model: json['model'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
    );
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

