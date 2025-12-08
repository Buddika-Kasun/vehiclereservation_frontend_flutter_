class TripBookingResponse {
  final bool success;
  final String message;
  final Trip? trip;
  final String? status;

  TripBookingResponse({
    required this.success,
    required this.message,
    this.trip,
    this.status,
  });

  factory TripBookingResponse.fromJson(Map<String, dynamic> json) {
    return TripBookingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      trip: json['trip'] != null ? Trip.fromJson(json['trip']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'trip': trip?.toJson(),
      'status': status,
    };
  }
}

class Trip {
  final int id;
  final String status;
  final String? driverName;
  final String? vehicleRegNo;
  final String? vehicleModel;
  final String? driverPhone;
  final String? arrivalTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? cost;
  final double? mileage;
  final double? startOdometer;
  final double? endOdometer;
  final String? purpose;
  final String? specialRemarks;
  final int? requesterId;
  final int? vehicleId;
  final int? approvalId;
  final int? odometerLogId;
  final int? feedbackId;
  final DateTime? startDate;
  final String? startTime;
  final DateTime? validTillDate;
  final String? repetition;
  final bool? includeWeekends;
  final int? repeatAfterDays;
  final String? passengerType;
  final int? passengerCount;
  final bool? includeMeInGroup;
  final int? locationId;
  final int? selectedIndividualId;

  Trip({
    required this.id,
    required this.status,
    this.driverName,
    this.vehicleRegNo,
    this.vehicleModel,
    this.driverPhone,
    this.arrivalTime,
    this.createdAt,
    this.updatedAt,
    this.cost,
    this.mileage,
    this.startOdometer,
    this.endOdometer,
    this.purpose,
    this.specialRemarks,
    this.requesterId,
    this.vehicleId,
    this.approvalId,
    this.odometerLogId,
    this.feedbackId,
    this.startDate,
    this.startTime,
    this.validTillDate,
    this.repetition,
    this.includeWeekends,
    this.repeatAfterDays,
    this.passengerType,
    this.passengerCount,
    this.includeMeInGroup,
    this.locationId,
    this.selectedIndividualId,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      driverName: json['driverName'],
      vehicleRegNo: json['vehicleRegNo'],
      vehicleModel: json['vehicleModel'],
      driverPhone: json['driverPhone'],
      arrivalTime: json['arrivalTime'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
      mileage: json['mileage'] != null ? double.tryParse(json['mileage'].toString()) : null,
      startOdometer: json['startOdometer'] != null ? double.tryParse(json['startOdometer'].toString()) : null,
      endOdometer: json['endOdometer'] != null ? double.tryParse(json['endOdometer'].toString()) : null,
      purpose: json['purpose'],
      specialRemarks: json['specialRemarks'],
      requesterId: json['requesterId'],
      vehicleId: json['vehicleId'],
      approvalId: json['approvalId'],
      odometerLogId: json['odometerLogId'],
      feedbackId: json['feedbackId'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      startTime: json['startTime'],
      validTillDate: json['validTillDate'] != null ? DateTime.parse(json['validTillDate']) : null,
      repetition: json['repetition'],
      includeWeekends: json['includeWeekends'],
      repeatAfterDays: json['repeatAfterDays'],
      passengerType: json['passengerType'],
      passengerCount: json['passengerCount'],
      includeMeInGroup: json['includeMeInGroup'],
      locationId: json['locationId'],
      selectedIndividualId: json['selectedIndividualId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'driverName': driverName,
      'vehicleRegNo': vehicleRegNo,
      'vehicleModel': vehicleModel,
      'driverPhone': driverPhone,
      'arrivalTime': arrivalTime,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cost': cost,
      'mileage': mileage,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'purpose': purpose,
      'specialRemarks': specialRemarks,
      'requesterId': requesterId,
      'vehicleId': vehicleId,
      'approvalId': approvalId,
      'odometerLogId': odometerLogId,
      'feedbackId': feedbackId,
      'startDate': startDate?.toIso8601String(),
      'startTime': startTime,
      'validTillDate': validTillDate?.toIso8601String(),
      'repetition': repetition,
      'includeWeekends': includeWeekends,
      'repeatAfterDays': repeatAfterDays,
      'passengerType': passengerType,
      'passengerCount': passengerCount,
      'includeMeInGroup': includeMeInGroup,
      'locationId': locationId,
      'selectedIndividualId': selectedIndividualId,
    };
  }
}