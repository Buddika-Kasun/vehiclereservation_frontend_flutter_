// lib/features/trips/widgets/checklist_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';

class VehicleChecklistCard extends StatelessWidget {
  final VehicleChecklistResponse checklist;
  final VoidCallback onTap;

  const VehicleChecklistCard({
    Key? key,
    required this.checklist,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSubmitted = checklist.isSubmitted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSubmitted ? Colors.grey[900] : Colors.grey[850],
      child: InkWell(
        onTap: isSubmitted ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isSubmitted ? 1.0 : 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVehicleInfo(),
                const SizedBox(height: 12),
                if (checklist.isSubmitted)
                  _buildCheckInfo()
                else
                  _buildNotSubmittedInfo(),
                if (checklist.isSubmitted) ...[
                  const SizedBox(height: 16),
                  _buildFooter(isSubmitted),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    final isSubmitted = checklist.isSubmitted;
    final hasStatus = checklist.status != null && checklist.status!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Reg No',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  checklist.vehicleRegNo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge - based on status
          if (isSubmitted && hasStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: checklist.getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: checklist.getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getStatusIcon(checklist.status!),
                  const SizedBox(width: 4),
                  Text(
                    checklist.getStatusText(),
                    style: TextStyle(
                      color: checklist.getStatusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // DRAFT badge for not submitted
          if (!isSubmitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'DRAFT',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckInfo() {
    return Column(
      children: [
        // Row 1: Checked By
        Row(
          children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Checked By:',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                checklist.checkedBy?.name ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Checked Date
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Checked Date:',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              checklist.formatCheckedDate(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotSubmittedInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            'Not checked yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isSubmitted) { 
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Click for full details',
            style: TextStyle(
              color: const Color(0xFFF9C80E),
              fontSize: 14,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: const Color(0xFFF9C80E),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icon(Icons.hourglass_top, size: 12, color: Colors.orange);
      case 'approved':
        return Icon(Icons.check_circle, size: 12, color: Colors.green);
      case 'rejected':
        return Icon(Icons.cancel, size: 12, color: Colors.red);
      default:
        return Icon(Icons.info, size: 12, color: Colors.grey);
    }
  }

}