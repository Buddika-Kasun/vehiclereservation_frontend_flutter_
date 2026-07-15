// lib/features/users/admin/vehicle_management/checklist/screens/checklist_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';

class ChecklistDetailsScreen extends StatefulWidget {
  final String checklistId;
  final bool hasActions;

  const ChecklistDetailsScreen({Key? key, required this.checklistId, this.hasActions = false})
    : super(key: key);

  @override
  _ChecklistDetailsScreenState createState() => _ChecklistDetailsScreenState();
}

class _ChecklistDetailsScreenState extends State<ChecklistDetailsScreen> {
  ChecklistResponse? _checklist;
  bool _isLoading = true;
  bool _isApproving = false;
  bool _isRejecting = false;
  final TextEditingController _commentController = TextEditingController();
  String _errorMessage = '';

  // Track expanded state for each item
  Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final checklist = await ApiService.getChecklistById(widget.checklistId);
      setState(() {
        _checklist = checklist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load checklist: ${e.toString()}';
        _isLoading = false;
      });
      MessageOverlay.showError(
        context: context,
        message: 'Failed to load checklist: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    }
  }

  void _refreshChecklist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedChecklist = await ApiService.getChecklistById(
        widget.checklistId,
      );
      setState(() {
        _checklist = updatedChecklist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      MessageOverlay.showError(
        context: context,
        message: 'Failed to refresh checklist: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    }
  }

  void _showApprovalDialog() {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Approve Checklist', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to approve this checklist?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add optional comments...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFF9C80E)),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: _isApproving
                ? null
                : () {
                    Navigator.pop(context);
                    _approveChecklist();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isApproving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog() {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Reject Checklist', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: TextStyle(color: Colors.white),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: _isRejecting
                ? null
                : () {
                    Navigator.pop(context);
                    _rejectChecklist();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isRejecting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveChecklist() async {
    if (_checklist == null) return;

    setState(() {
      _isApproving = true;
    });

    try {
      final response = await ApiService.approveChecklist(
        checklistId: _checklist!.id,
        comment: _commentController.text,
      );

      if (response['success'] == true) {
        MessageOverlay.showSuccess(
          context: context,
          message: 'Checklist approved successfully!',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: Duration(seconds: 2),
          onComplete: () {
            _refreshChecklist();
          },
        );
      } else {
        throw Exception(response['message'] ?? 'Approval failed');
      }
    } catch (e) {
      MessageOverlay.showError(
        context: context,
        message: 'Error approving checklist: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    } finally {
      setState(() {
        _isApproving = false;
      });
    }
  }

  Future<void> _rejectChecklist() async {
    if (_checklist == null) return;

    setState(() {
      _isRejecting = true;
    });

    try {
      final response = await ApiService.rejectChecklist(
        checklistId: _checklist!.id,
        comment: _commentController.text,
      );

      if (response['success'] == true) {
        MessageOverlay.showSuccess(
          context: context,
          message: 'Checklist rejected successfully!',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: Duration(seconds: 2),
          onComplete: () {
            _refreshChecklist();
          },
        );
      } else {
        throw Exception(response['message'] ?? 'Rejection failed');
      }
    } catch (e) {
      MessageOverlay.showError(
        context: context,
        message: 'Error rejecting checklist: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    } finally {
      setState(() {
        _isRejecting = false;
      });
    }
  }

  String _getSriLankanTime(DateTime utcTime) {
    const sriLankanOffset = Duration(hours: 5, minutes: 30);
    final localTime = utcTime.add(sriLankanOffset);
    return DateFormat('hh:mm a').format(localTime);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 60.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF9C80E)),
                  SizedBox(height: 16),
                  Text(
                    'Loading checklist...',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadChecklist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF9C80E),
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : _checklist == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    color: Colors.grey[600],
                    size: 50,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Checklist not found',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  height: statusBarHeight + appBarHeight,
                  padding: EdgeInsets.only(
                    top: statusBarHeight,
                    left: 16,
                    right: 16,
                    bottom: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFF9C80E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Checklist Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_checklist!.status != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _checklist!.status!,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _checklist!.getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(_checklist!.status!),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildVehicleInfoSection(),
                        SizedBox(height: 16),
                        _buildInfoSection(),
                        SizedBox(height: 16),
                        _buildCheckedBySection(),
                        SizedBox(height: 16),
                        if (_checklist!.status == 'approved' &&
                            _checklist!.approvedBy != null) ...[
                          _buildApprovedBySection(),
                          SizedBox(height: 16),
                        ],
                        if (_checklist!.status == 'rejected') ...[
                          _buildRejectionInfoSection(),
                          SizedBox(height: 16),
                        ],
                        _buildChecklistItemsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildVehicleInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFF9C80E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_car,
              color: Color(0xFFF9C80E),
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Reg No',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  _checklist!.vehicleRegNo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFF9C80E), size: 20),
              SizedBox(width: 8),
              Text(
                _formatDate(_checklist!.checklistDate),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '#${_checklist!.id}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          /*
          SizedBox(height: 12),
          Divider(color: Colors.grey[800]),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist ID',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '#${_checklist!.id}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Submitted At',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getSriLankanTime(_checklist!.createdAt),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          */
        ],
      ),
    );
  }

  Map<String, List<String>> _getChecklistSections() {
    return {
      'Tyre & Suspension System': [
        'Tyre condition',
        'Extra tyre condition',
        'Air pressure condition',
      ],
      'Light System': ['Main lamp', 'Signal', 'Break light', 'Parking', 'Horn'],
      'Break System': ['Paddle pressure', 'Hand break'],
      'Engine': [
        'Normal start',
        'Not bad sound',
        'No oil leak',
        'No bad Smoke',
      ],
      'Windscreen': [
        'Wind screen condition',
        'Wiper condition',
        'Clearness and water level',
      ],
      'Seat Belt System': ['Belt condition', 'Locks condition'],
      'Steering System': ['Power steering oil level', 'Steering condition'],
      'Vehicle Outside': ['Side mirror condition', 'Outside cleanliness'],
      'Vehicle Inside': [
        'Inside cleanliness',
        'Seats condition',
        'Seat adjusting condition',
        'AC condition',
        'Toolkit',
      ],
      'Safety Items': [
        'First aid box',
        'Vehicle breakdown triangle',
        'Luminous packet',
        'Fire extinguisher',
        'Personal safety tool',
      ],
    };
  }

  Widget _buildChecklistItemsSection() {
    final items = _checklist!.responses;
    if (items.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No checklist items found',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    final sections = _getChecklistSections();

    return Column(
      children: sections.entries.map((sectionEntry) {
        final sectionName = sectionEntry.key;
        final sectionItems = sectionEntry.value;

        // Filter items that exist in the response
        final availableItems = sectionItems
            .where((item) => items.containsKey(item))
            .toList();

        if (availableItems.isEmpty) return SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSectionIcon(sectionName),
                      color: Color(0xFFF9C80E),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sectionName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[800], height: 1),
              // Section Items
              ...availableItems.map(
                (item) =>
                    _buildChecklistItem(itemName: item, response: items[item]!),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Add helper method for section icons
  IconData _getSectionIcon(String sectionName) {
    switch (sectionName) {
      case 'Tyre & Suspension System':
        return Icons.tire_repair;
      case 'Light System':
        return Icons.lightbulb;
      case 'Break System':
        return Icons.emergency;
      case 'Engine':
        return Icons.engineering;
      case 'Windscreen':
        return Icons.wind_power;
      case 'Seat Belt System':
        return Icons.safety_check;
      case 'Steering System':
        return Icons.directions_car;
      case 'Vehicle Outside':
        return Icons.car_repair;
      case 'Vehicle Inside':
        return Icons.airline_seat_recline_normal;
      case 'Safety Items':
        return Icons.security;
      default:
        return Icons.checklist;
    }
  }

  // Update the _buildChecklistItem method to remove the divider (since section handles it)
  Widget _buildChecklistItem({
    required String itemName,
    required ChecklistItemResponse response,
  }) {
    final isGood = response.status == 'good';
    final isBad = response.status == 'bad';
    final hasRemarks = response.remarks != null && response.remarks!.isNotEmpty;

    // Initialize expanded state
    if (!_expandedItems.containsKey(itemName)) {
      _expandedItems[itemName] = false;
    }

    return Column(
      children: [
        InkWell(
          onTap: hasRemarks
              ? () {
                  setState(() {
                    _expandedItems[itemName] = !_expandedItems[itemName]!;
                  });
                }
              : null,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isGood
                        ? Colors.green.withOpacity(0.2)
                        : isBad
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGood
                        ? Icons.check
                        : isBad
                        ? Icons.close
                        : Icons.help_outline,
                    size: 14,
                    color: isGood
                        ? Colors.green
                        : isBad
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasRemarks) ...[
                  Icon(Icons.comment, size: 16, color: Colors.grey[400]),
                  SizedBox(width: 4),
                  Icon(
                    _expandedItems[itemName]!
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expandedItems[itemName]! && hasRemarks)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              response.remarks!,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        if (hasRemarks && _expandedItems[itemName]!) SizedBox(height: 8),
        Divider(color: Colors.grey[800], height: 1),
      ],
    );
  }

  Widget _buildCheckedBySection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checked By',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.blue, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _checklist!.checkedBy.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _checklist!.checkedBy.role.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getSriLankanTime(_checklist!.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedBySection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Approved By',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.green, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _checklist!.approvedBy?.name ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _checklist!.approvedBy?.role.toUpperCase() ?? '',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getSriLankanTime(_checklist!.updatedAt!),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          if (_checklist!.comment != null &&
              _checklist!.comment!.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Approval Comment:',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _checklist!.comment!,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Rejected',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.red, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _checklist!.approvedBy?.name ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _checklist!.approvedBy?.role.toUpperCase() ?? '',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getSriLankanTime(_checklist!.updatedAt!),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          if (_checklist!.comment != null &&
              _checklist!.comment!.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Rejection Reason:',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _checklist!.comment!,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_checklist == null || !widget.hasActions) return SizedBox.shrink();

    // Only show action buttons for pending checklists
    if (_checklist!.status != 'submitted') {
      return SizedBox.shrink();
    }

    // Check if current user is authorized to approve (sysadmin or supervisor)
    final currentUser = StorageService.userData;
    final isAuthorized =
        currentUser?.role.value.toLowerCase() == 'sysadmin' ||
        currentUser?.role.value.toLowerCase() == 'supervisor';

    if (!isAuthorized) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isRejecting ? null : _showRejectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 8),
                  Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isApproving ? null : _showApprovalDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

}
