import 'package:flutter/material.dart';

class ApprovalTrip {
  final int id;
  final String requesterName;
  //final String requesterEmail;
  //final String purpose;
  final String startLocation;
  final String endLocation;
  final DateTime startDate;
  final String startTime;
  final String vehicleModel;
  final String vehicleRegNo;
  final String status;
  //final int passengerCount;
  final DateTime requestedAt;
  final String approvalStep; // 'hod', 'secondary', 'safety'

  ApprovalTrip({
    required this.id,
    required this.requesterName,
    //required this.requesterEmail,
    //required this.purpose,
    required this.startLocation,
    required this.endLocation,
    required this.startDate,
    required this.startTime,
    required this.vehicleModel,
    required this.vehicleRegNo,
    required this.status,
    //required this.passengerCount,
    required this.requestedAt,
    required this.approvalStep,
  });

  factory ApprovalTrip.fromJson(Map<String, dynamic> json) {
    return ApprovalTrip(
      id: json['id'] ?? 0,
      requesterName: json['requesterName'] ?? 'Unknown',
      //requesterEmail: json['requesterEmail'] ?? '',
      //purpose: json['purpose'] ?? '',
      startLocation: json['startLocation'] ?? '',
      endLocation: json['endLocation'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      vehicleModel: json['vehicleModel'] ?? 'Unknown',
      vehicleRegNo: json['vehicleRegNo'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      //passengerCount: json['passengerCount'] ?? 1,
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      approvalStep: json['approvalStep'] ?? 'hod',
    );
  }
}