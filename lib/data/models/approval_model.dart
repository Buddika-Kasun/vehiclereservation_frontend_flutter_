// Update your ApprovalTrip model
class ApprovalTrip {
  final int id;
  final String requesterName;
  final String startLocation;
  final String endLocation;
  final DateTime startDate;
  final String startTime;
  final String vehicleModel;
  final String vehicleRegNo;
  final String status;
  final DateTime requestedAt;
  final String approvalStep;

  // NEW FIELDS FOR SCHEDULED TRIPS
  final bool isScheduled;
  final bool isInstance;
  final int? masterTripId;
  final int? instanceCount;
  final List<int>? instanceIds;

  ApprovalTrip({
    required this.id,
    required this.requesterName,
    required this.startLocation,
    required this.endLocation,
    required this.startDate,
    required this.startTime,
    required this.vehicleModel,
    required this.vehicleRegNo,
    required this.status,
    required this.requestedAt,
    required this.approvalStep,

    // NEW: Scheduled trip fields with defaults
    this.isScheduled = false,
    this.isInstance = false,
    this.masterTripId,
    this.instanceCount = 0,
    this.instanceIds,
  });

  factory ApprovalTrip.fromJson(Map<String, dynamic> json) {
    return ApprovalTrip(
      id: json['id'] ?? 0,
      requesterName: json['requesterName'] ?? 'Unknown',
      startLocation: json['startLocation'] ?? '',
      endLocation: json['endLocation'] ?? '',
      startDate: DateTime.parse(
        json['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      startTime: json['startTime'] ?? '',
      vehicleModel: json['vehicleModel'] ?? 'Unknown',
      vehicleRegNo: json['vehicleRegNo'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(
        json['requestedAt'] ?? DateTime.now().toIso8601String(),
      ),
      approvalStep: json['approvalStep'] ?? 'hod',

      // NEW: Parse scheduled trip fields
      isScheduled: json['isScheduled'] ?? false,
      isInstance: json['isInstance'] ?? false,
      masterTripId: json['masterTripId'],
      instanceCount: json['instanceCount'] ?? 0,
      instanceIds: json['instanceIds'] != null
          ? List<int>.from(json['instanceIds'])
          : null,
    );
  }
}

