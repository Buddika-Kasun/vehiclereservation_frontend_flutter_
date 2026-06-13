// lib/features/trips/widgets/checklist_card.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';

class ChecklistCard extends StatelessWidget {
  final ChecklistResponse checklist;
  final VoidCallback onTap;

  const ChecklistCard({
    Key? key,
    required this.checklist,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildVehicleInfo(),
              const SizedBox(height: 12),
              _buildCheckInfo(),
              if (checklist.status != 'submitted') ...[
                const SizedBox(height: 12),
                _buildActionInfo(),
              ],
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Checklist ID
        Expanded(
          child: Text(
            'Checklist #${checklist.id}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: checklist.getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                checklist.status == 'pending'
                    ? Icons.hourglass_top
                    : checklist.status == 'approved'
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 14,
                color: checklist.getStatusColor(),
              ),
              const SizedBox(width: 4),
              Text(
                checklist.getStatusText(),
                style: TextStyle(
                  color: checklist.getStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
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
                checklist.checkedBy.name,
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
 
  Widget _buildActionInfo() {
    final isApproved = checklist.status?.toLowerCase() == 'approved';
    final actionBy = checklist.approvedBy?.name ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        //border: Border.all(
        //  color: isApproved ? Colors.green : Colors.red,
        //  width: 0.5,
        //),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isApproved ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApproved ? 'Approved By' : 'Rejected By',
                  style: TextStyle(
                    color: isApproved ? Colors.green : Colors.red,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  actionBy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Click for full details',
            style: TextStyle(color: Color(0xFFF9C80E), fontSize: 14),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFF9C80E),
            size: 16,
          ),
        ],
      ),
    );
  }

}
