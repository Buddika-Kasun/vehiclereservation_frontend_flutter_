import 'package:flutter/material.dart';

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return Colors.yellowAccent;
    case 'pending':
      return Colors.orangeAccent;
    case 'approved':
      return Colors.greenAccent;
    case 'read':
      return Colors.cyanAccent;
    case 'ongoing':
      return Colors.blueAccent;
    case 'completed':
      return Colors.purpleAccent;
    case 'canceled':
      return Colors.redAccent;
    case 'rejected':
      return Colors.red[300]!;
    case 'finished':
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

String tripTypeLabel(String tripType) {
  switch (tripType) {
    case 'RP':
      return 'RP';
    case 'RO':
      return 'RO';
    case 'P':
      return 'P';
    case 'J':
      return 'J';
    default:
      return 'R';
  }
}

Color tripTypeColor(String tripType) {
  switch (tripType) {
    case 'RP':
      return Colors.greenAccent;
    case 'RO':
      return Colors.yellowAccent;
    case 'P':
      return Colors.purpleAccent;
    case 'J':
      return Colors.orangeAccent;
    default:
      return Colors.grey;
  }
}

String getTripStatusLabel(String? status) {
  switch (status?.toLowerCase()) {
    case 'draft':
      return 'Draft';
    case 'pending':
    case 'pendingforme':
      return 'Pending';
    case 'approved':
      return 'Approved';
    case 'read':
      return 'Read';
    case 'ongoing':
      return 'Ongoing';
    case 'completed':
      return 'Completed';
    case 'canceled':
      return 'Canceled';
    case 'rejected':
      return 'Rejected';
    case 'finished':
      return 'Finished';
    case 'needread':
      return 'Need Reading';
    case 'alreadyread':
      return 'Already Read';
    case 'scheduled':
      return 'Scheduled';
    case 'normal':
      return 'Normal';
    case 'exceed':
      return 'Exceed';
    case 'accepted':
      return 'Accepted';
    default:
      return 'All';
  }
}