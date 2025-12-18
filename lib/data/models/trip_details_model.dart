import 'dart:convert';

class TripDetails {
  final int id;
  final Requester requester;
  final String status;
  final String? purpose;
  final String? specialRemarks;
  final String startDate;
  final String startTime;
  final String repetition;
  final String passengerType;
  final int passengerCount;
  final bool includeMeInGroup;
  final double? cost;
  final String mileage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Vehicle vehicle;
  final Location location;
  final Details details;
  final Conflicts conflicts;
  final Schedule schedule;

  TripDetails({
    required this.id,
    required this.requester,
    required this.status,
    this.purpose,
    this.specialRemarks,
    required this.startDate,
    required this.startTime,
    required this.repetition,
    required this.passengerType,
    required this.passengerCount,
    required this.includeMeInGroup,
    this.cost,
    required this.mileage,
    required this.createdAt,
    required this.updatedAt,
    required this.vehicle,
    required this.location,
    required this.details,
    required this.conflicts,
    required this.schedule,
  });

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    return TripDetails(
      id: json['id'] ?? 0,
      
      status: json['status'] ?? '',
      purpose: json['purpose'],
      specialRemarks: json['specialRemarks'],
      startDate: json['startDate'] ?? '',
      startTime: json['startTime'] ?? '',
      repetition: json['repetition'] ?? '',
      passengerType: json['passengerType'] ?? '',
      passengerCount: json['passengerCount'] ?? 0,
      includeMeInGroup: json['includeMeInGroup'] ?? false,
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
      mileage: json['mileage'] ?? '0',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      requester: Requester.fromJson(json['requester'] ?? {}),
      vehicle: Vehicle.fromJson(json['vehicle'] ?? {}),
      location: Location.fromJson(json['location'] ?? {}),
      details: Details.fromJson(json['details'] ?? {}),
      conflicts: Conflicts.fromJson(json['details']['conflicts'] ?? {}),
      schedule: Schedule.fromJson(json['schedule'] ?? {}),
    );
  }
}

class Requester {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String department;

  Requester({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
  });

  factory Requester.fromJson(Map<String, dynamic> json) {
    return Requester(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? '',
    );
  }
}

class Vehicle {
  final int id;
  final String model;
  final String regNo;
  final String vehicleType;
  final int seatingCapacity;
  final int seatingAvailability;

  Vehicle({
    required this.id,
    required this.model,
    required this.regNo,
    required this.vehicleType,
    required this.seatingCapacity,
    required this.seatingAvailability,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      model: json['model'] ?? '',
      regNo: json['regNo'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      seatingCapacity: json['seatingCapacity'] ?? 0,
      seatingAvailability: json['seatingAvailability'] ?? 0,
    );
  }
}

class Location {
  final String startAddress;
  final String endAddress;
  final int totalStops;

  Location({
    required this.startAddress,
    required this.endAddress,
    required this.totalStops,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      startAddress: json['startAddress'] ?? '',
      endAddress: json['endAddress'] ?? '',
      totalStops: json['totalStops'] ?? 0,
    );
  }
}

class Details {
  final Passengers passengers;
  final Approval approval;
  final Drivers drivers;
  final Route route;
  final VehicleDetails vehicleDetails;

  Details({
    required this.passengers,
    required this.approval,
    required this.drivers,
    required this.route,
    required this.vehicleDetails,
  });

  factory Details.fromJson(Map<String, dynamic> json) {
    return Details(
      passengers: Passengers.fromJson(json['passengers'] ?? {}),
      approval: Approval.fromJson(json['approval'] ?? {}),
      drivers: Drivers.fromJson(json['drivers'] ?? {}),
      route: Route.fromJson(json['route'] ?? {}),
      vehicleDetails: VehicleDetails.fromJson(json['vehicleDetails'] ?? {}),
    );
  }
}

class Passengers {
  final int total;
  final List<Passenger> list;
  final String passengerType;
  final bool includeMeInGroup;

  Passengers({
    required this.total,
    required this.list,
    required this.passengerType,
    required this.includeMeInGroup,
  });

  factory Passengers.fromJson(Map<String, dynamic> json) {
    final passengersList = json['list'] as List<dynamic>? ?? [];
    return Passengers(
      total: json['total'] ?? 0,
      list: passengersList.map((p) => Passenger.fromJson(p)).toList(),
      passengerType: json['passengerType'] ?? '',
      includeMeInGroup: json['includeMeInGroup'] ?? false,
    );
  }
}

class Passenger {
  final dynamic id;
  final String name;
  final String? email;
  final String? contactNo;
  final String? department;
  final String type;

  Passenger({
    required this.id,
    required this.name,
    this.email,
    this.contactNo,
    this.department,
    required this.type,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      contactNo: json['contactNo'] ?? json['phone'],
      department: json['department'],
      type: json['type'] ?? '',
    );
  }
}

class Approval {
  final bool hasApproval;
  final String overallStatus;
  final String currentStep;
  final Approvers approvers;
  final Requirements requirements;
  final String? comments;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Approval({
    required this.hasApproval,
    required this.overallStatus,
    required this.currentStep,
    required this.approvers,
    required this.requirements,
    this.comments,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      hasApproval: json['hasApproval'] ?? false,
      overallStatus: json['overallStatus'] ?? '',
      currentStep: json['currentStep'] ?? '',
      approvers: Approvers.fromJson(json['approvers'] ?? {}),
      requirements: Requirements.fromJson(json['requirements'] ?? {}),
      comments: json['comments'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Approvers {
  final Approver? hod;
  final Approver? secondary;
  final Approver? safety;

  Approvers({
    this.hod,
    this.secondary,
    this.safety,
  });

  factory Approvers.fromJson(Map<String, dynamic> json) {
    return Approvers(
      hod: json['hod'] != null ? Approver.fromJson(json['hod']) : null,
      secondary: json['secondary'] != null ? Approver.fromJson(json['secondary']) : null,
      safety: json['safety'] != null ? Approver.fromJson(json['safety']) : null,
    );
  }
}

class Approver {
  final int? id;
  final String? name;
  final String? department;
  final String status;
  final DateTime? approvedAt;
  final String? comments;

  Approver({
    this.id,
    this.name,
    this.department,
    required this.status,
    this.approvedAt,
    this.comments,
  });

  factory Approver.fromJson(Map<String, dynamic> json) {
    return Approver(
      id: json['id'],
      name: json['name'],
      department: json['department'],
      status: json['status'] ?? 'pending',
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      comments: json['comments'],
    );
  }
}

class Requirements {
  final bool requireApprover1;
  final bool requireApprover2;
  final bool requireSafetyApprover;

  Requirements({
    required this.requireApprover1,
    required this.requireApprover2,
    required this.requireSafetyApprover,
  });

  factory Requirements.fromJson(Map<String, dynamic> json) {
    return Requirements(
      requireApprover1: json['requireApprover1'] ?? false,
      requireApprover2: json['requireApprover2'] ?? false,
      requireSafetyApprover: json['requireSafetyApprover'] ?? false,
    );
  }
}

class Drivers {
  final bool hasDrivers;
  final Driver? primary;
  final Driver? secondary;

  Drivers({
    required this.hasDrivers,
    this.primary,
    this.secondary,
  });

  factory Drivers.fromJson(Map<String, dynamic> json) {
    return Drivers(
      hasDrivers: json['hasDrivers'] ?? false,
      primary: json['primary'] != null ? Driver.fromJson(json['primary']) : null,
      secondary: json['secondary'] != null ? Driver.fromJson(json['secondary']) : null,
    );
  }
}

class Driver {
  final int id;
  final String name;
  final String phone;
  final String role;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class Route {
  final bool hasRoute;
  final Coordinates coordinates;
  final Stops stops;
  final Metrics metrics;
  final RawData? rawData;

  Route({
    required this.hasRoute,
    required this.coordinates,
    required this.stops,
    required this.metrics,
    this.rawData,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      hasRoute: json['hasRoute'] ?? false,
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
      stops: Stops.fromJson(json['stops'] ?? {}),
      metrics: Metrics.fromJson(json['metrics'] ?? {}),
      rawData: json['rawData'] != null ? RawData.fromJson(json['rawData']) : null,
    );
  }
}

class Coordinates {
  final Coordinate start;
  final Coordinate end;

  Coordinates({
    required this.start,
    required this.end,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      start: Coordinate.fromJson(json['start'] ?? {}),
      end: Coordinate.fromJson(json['end'] ?? {}),
    );
  }
}

class Coordinate {
  final double latitude;
  final double longitude;
  final String address;

  Coordinate({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      address: json['address'] ?? '',
    );
  }
}

class Stops {
  final List<IntermediateStop> intermediate;
  final int total;

  Stops({
    required this.intermediate,
    required this.total,
  });

  factory Stops.fromJson(Map<String, dynamic> json) {
    final intermediateList = json['intermediate'] as List<dynamic>? ?? [];
    return Stops(
      intermediate: intermediateList.map((s) => IntermediateStop.fromJson(s)).toList(),
      total: json['total'] ?? 0,
    );
  }
}

class IntermediateStop {
  final int order;
  final String address;
  final double latitude;
  final double longitude;

  IntermediateStop({
    required this.order,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory IntermediateStop.fromJson(Map<String, dynamic> json) {
    return IntermediateStop(
      order: json['order'] ?? 0,
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Metrics {
  final String distance;
  final String estimatedDuration;

  Metrics({
    required this.distance,
    required this.estimatedDuration,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      distance: json['distance'] ?? '0',
      estimatedDuration: json['estimatedDuration'] ?? '0',
    );
  }
}

class VehicleDetails {
  final int id;
  final Specifications specifications;
  final Capacity capacity;
  final Status status;

  VehicleDetails({
    required this.id,
    required this.specifications,
    required this.capacity,
    required this.status,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      id: json['id'] ?? 0,
      specifications: Specifications.fromJson(json['specifications'] ?? {}),
      capacity: Capacity.fromJson(json['capacity'] ?? {}),
      status: Status.fromJson(json['status'] ?? {}),
    );
  }
}

class Specifications {
  final String model;
  final String regNo;
  final String fuelType;
  final String vehicleType;

  Specifications({
    required this.model,
    required this.regNo,
    required this.fuelType,
    required this.vehicleType,
  });

  factory Specifications.fromJson(Map<String, dynamic> json) {
    return Specifications(
      model: json['model'] ?? '',
      regNo: json['regNo'] ?? '',
      fuelType: json['fuelType'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
    );
  }
}

class Capacity {
  final int seating;
  final int available;

  Capacity({
    required this.seating,
    required this.available,
  });

  factory Capacity.fromJson(Map<String, dynamic> json) {
    return Capacity(
      seating: json['seating'] ?? 0,
      available: json['available'] ?? 0,
    );
  }
}

class Status {
  final bool isActive;
  final String odometerLastReading;

  Status({
    required this.isActive,
    required this.odometerLastReading,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      isActive: json['isActive'] ?? false,
      odometerLastReading: json['odometerLastReading'] ?? '0',
    );
  }
}

class Conflicts {
  final bool hasConflicts;
  final int count;
  final List<ConflictTrip> trips;
  final String message;
  final String? reason;

  Conflicts({
    required this.hasConflicts,
    required this.count,
    required this.trips,
    required this.message,
    this.reason,
  });

  factory Conflicts.fromJson(Map<String, dynamic> json) {
    final tripsList = json['trips'] as List<dynamic>? ?? [];
    return Conflicts(
      hasConflicts: json['hasConflicts'] ?? false,
      count: json['count'] ?? 0,
      trips: tripsList.map((t) => ConflictTrip.fromJson(t)).toList(),
      message: json['message'] ?? '',
      reason: json['reason'],
    );
  }
}

class ConflictTrip {
  final int id;

  ConflictTrip({
    required this.id,
  });

  factory ConflictTrip.fromJson(Map<String, dynamic> json) {
    return ConflictTrip(
      id: json['id'] ?? 0,
    );
  }
}

class RawData {
  final List<RouteSegment> routeSegments;

  RawData({
    required this.routeSegments,
  });

  factory RawData.fromJson(Map<String, dynamic> json) {
    final segmentsList = json['routeSegments'] as List<dynamic>? ?? [];
    return RawData(
      routeSegments: segmentsList.map((s) => RouteSegment.fromJson(s)).toList(),
    );
  }
}

class RouteSegment {
  final int color;
  final List<List<double>> points;
  final int strokeWidth;

  RouteSegment({
    required this.color,
    required this.points,
    required this.strokeWidth,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List<dynamic>? ?? [];
    return RouteSegment(
      color: json['color'] ?? 0xFF2196F3,
      points: pointsList.map((point) {
        final List<dynamic> coords = point as List<dynamic>;
        return [coords[0] as double, coords[1] as double];
      }).toList(),
      strokeWidth: json['strokeWidth'] ?? 5,
    );
  }
}

class Schedule {
  final bool isScheduled;
  final bool isInstance;
  final int? masterTripId;
  final String? instanceDate;
  final String? validTillDate;
  final bool includeWeekends;
  final int? repeatAfterDays;
  final int instanceCount;
  final List<InstanceInfo>?  instanceIds; 

  Schedule({
    required this.isScheduled,
    required this.isInstance,
    this.masterTripId,
    this.instanceDate,
    this.validTillDate,
    required this.includeWeekends,
    this.repeatAfterDays,
    required this.instanceCount,
    this.instanceIds,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      isScheduled: json['isScheduled'] ?? false,
      isInstance: json['isInstance'] ?? false,
      masterTripId: json['masterTripId'],
      instanceDate: json['instanceDate'],
      validTillDate: json['validTillDate'],
      includeWeekends: json['includeWeekends'] ?? false,
      repeatAfterDays: json['repeatAfterDays'],
      instanceCount: json['instanceCount'] ?? 0,
      instanceIds: json['instanceIds'] != null
          ? List<InstanceInfo>.from(
              json['instanceIds'].map((x) => InstanceInfo.fromJson(x)),
            )
          : null,
    );
  }
}

// Add new class for instance info
class InstanceInfo {
  final int id;
  final String startDate;

  InstanceInfo({required this.id, required this.startDate});

  factory InstanceInfo.fromJson(Map<String, dynamic> json) {
    return InstanceInfo(
      id: json['id'] ?? 0,
      startDate: json['startDate'] ?? '',
    );
  }
}

