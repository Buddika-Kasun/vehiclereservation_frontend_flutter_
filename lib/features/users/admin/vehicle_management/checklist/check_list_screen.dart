import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';

class ChecklistScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleRegNo;
  final String userId;
  final String userName;
  final String userRole;

  const ChecklistScreen({
    Key? key,
    required this.vehicleId,
    required this.vehicleRegNo,
    required this.userId,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  // Filters
  String _currentFilter = 'today';
  DateTime? _selectedDate;

  // Checklist data
  ChecklistResponse? _existingChecklist;
  List<ChecklistResponse> _allChecklists = [];
  bool _hasRecord = false;
  bool _isViewOnly = false;
  int _currentVersion = 0;

  // Checklist Form State
  Map<String, Map<String, dynamic>> _checklistResponses = {};
  Map<String, TextEditingController> _reasonControllers = {};

  // Track expanded state for each item
  Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadChecklistData();
  }

  @override
  void dispose() {
    _reasonControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeChecklistForm() {
    final checklistItems = _getChecklistSections();

    _checklistResponses.clear();
    _reasonControllers.values.forEach((controller) => controller.dispose());
    _reasonControllers.clear();

    for (var section in checklistItems.keys) {
      for (var item in checklistItems[section]!) {
        _checklistResponses[item] = {'status': null, 'remarks': ''};
        _reasonControllers[item] = TextEditingController();
      }
    }
  }

  Future<void> _loadChecklistData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _expandedItems.clear();
        _allChecklists.clear();
      });

      final currentDate = _selectedDate ?? DateTime.now();
      final isToday = _isToday(currentDate);

      print('📅 Loading checklist for date: $currentDate');
      print('📅 Is Today: $isToday');

      // Fetch all versions
      await _fetchAllVersions(currentDate);

      // Check if any checklists exist
      bool exists = _allChecklists.isNotEmpty;
      print('✅ Checklists exist: $exists, Count: ${_allChecklists.length}');

      if (_allChecklists.isNotEmpty) {
        // Get the latest checklist (last one after sorting)
        final latestChecklist = _allChecklists.last;
        print(
          '✅ Latest checklist: ID=${latestChecklist.id}, Status=${latestChecklist.status}, Version=${latestChecklist.version}',
        );

        setState(() {
          _existingChecklist = latestChecklist;
          _hasRecord = true;
          _isViewOnly = true;
          _currentVersion = latestChecklist.version ?? _allChecklists.length;
          _loadExistingChecklistData(latestChecklist);
          _isLoading = false;
        });
      } else {
        // No checklists exist
        if (isToday) {
          setState(() {
            _hasRecord = false;
            _isViewOnly = false;
            _existingChecklist = null;
            _currentVersion = 0;
            _initializeChecklistForm();
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasRecord = false;
            _isViewOnly = true;
            _existingChecklist = null;
            _currentVersion = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error in _loadChecklistData: $e');
      setState(() {
        _errorMessage = 'Error loading checklist: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllVersions(DateTime date) async {
    try {
      print('📚 Fetching all versions for date: $date');

      final allChecklists = await ApiService.getAllChecklistsByDate(
        vehicleId: widget.vehicleId,
        date: date,
      );

      print('📚 Raw response length: ${allChecklists.length}');

      if (allChecklists.isEmpty) {
        print('ℹ️ No checklists found for this date');
        setState(() {
          _allChecklists = [];
          _currentVersion = 0;
        });
        return;
      }

      // Sort by version number
      allChecklists.sort((a, b) {
        final versionA = a.version ?? int.tryParse(a.id) ?? 0;
        final versionB = b.version ?? int.tryParse(b.id) ?? 0;
        return versionA.compareTo(versionB);
      });

      setState(() {
        _allChecklists = allChecklists;
        _currentVersion = allChecklists.isNotEmpty
            ? (allChecklists.last.version ?? allChecklists.length)
            : 0;
      });

      print('📚 Total versions found: ${allChecklists.length}');
      for (var i = 0; i < allChecklists.length; i++) {
        print(
          '  Version ${allChecklists[i].version ?? i + 1}: ID=${allChecklists[i].id}, Status=${allChecklists[i].status}',
        );
      }
    } catch (e) {
      print('⚠️ Error fetching all versions: $e');
      setState(() {
        _allChecklists = [];
        _currentVersion = 0;
      });
    }
  }

  void _loadExistingChecklistData(ChecklistResponse checklist) {
    final checklistItems = _getChecklistSections();

    _checklistResponses.clear();
    _reasonControllers.values.forEach((controller) => controller.dispose());
    _reasonControllers.clear();

    print('Loading checklist data from API response...');
    print('Total responses from API: ${checklist.responses.length}');

    for (var section in checklistItems.keys) {
      for (var item in checklistItems[section]!) {
        final response = checklist.responses[item];
        if (response != null) {
          final status = response.status;
          final remarks = response.remarks ?? '';

          _checklistResponses[item] = {
            'status': status ?? '',
            'remarks': remarks,
          };

          _reasonControllers[item] = TextEditingController(text: remarks);
        } else {
          _checklistResponses[item] = {'status': '', 'remarks': ''};
          _reasonControllers[item] = TextEditingController();
        }
      }
    }

    print('✅ Total items loaded to UI: ${_checklistResponses.length}');
  }

  void _refreshChecklist() {
    _loadChecklistData();
  }

  void _setFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _selectedDate = null;
    });
    _loadChecklistData();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFF9C80E),
              onPrimary: Colors.black,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _currentFilter = 'date';
      });
      _loadChecklistData();
    }
  }

  void _updateChecklistItem(String item, String? status) {
    if (_isViewOnly || _isSubmitting) return;

    setState(() {
      _checklistResponses[item]!['status'] = status;
    });
  }

  void _updateRemarks(String item, String remarks) {
    if (_isViewOnly || _isSubmitting) return;

    setState(() {
      _checklistResponses[item]!['remarks'] = remarks;
    });
  }

  Future<void> _submitChecklist() async {
    if (_isViewOnly || _isSubmitting) return;

    bool allChecked = true;
    final uncheckedItems = [];
    final checklistItems = _getChecklistSections();

    for (var section in checklistItems.keys) {
      for (var item in checklistItems[section]!) {
        final status = _checklistResponses[item]!['status'];
        if (status == null || status == '') {
          allChecked = false;
          uncheckedItems.add(item);
        }
      }
    }

    if (!allChecked) {
      MessageOverlay.showError(
        context: context,
        message:
            'Please check all items before submitting. Missing: ${uncheckedItems.length} items',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final Map<String, ChecklistItemRequest> apiResponses = {};

      for (var item in _checklistResponses.keys) {
        final status = _checklistResponses[item]!['status'] as String?;
        final remarks = _checklistResponses[item]!['remarks'] as String?;

        if (status != null && status.isNotEmpty) {
          apiResponses[item] = ChecklistItemRequest(
            status: status,
            remarks: remarks,
          );
        }
      }

      await ApiService.submitChecklist(
        vehicleId: widget.vehicleId,
        vehicleRegNo: widget.vehicleRegNo,
        checklistDate: _selectedDate ?? DateTime.now(),
        checkedById: widget.userId,
        checkedByName: widget.userName,
        checkedByRole: widget.userRole,
        responses: apiResponses,
      );

      await _loadChecklistData();

      MessageOverlay.showSuccess(
        context: context,
        message:
            'Checklist submitted successfully! Version ${_allChecklists.length}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        duration: const Duration(seconds: 2),
        onComplete: () {},
      );
    } catch (e) {
      print('❌ Error submitting checklist: $e');
      MessageOverlay.showError(
        context: context,
        message: 'Error submitting checklist: ${e.toString()}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _resubmitChecklist() async {
    _initializeChecklistForm();
    setState(() {
      _isViewOnly = false;
      _hasRecord = false;
      _existingChecklist = null;
      _currentVersion = _allChecklists.length;
    });
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
        'Dashboard camera',
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate == today;
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'draft':
        return 'NOT SUBMITTED';
      case 'submitted':
        return 'REVIEWING';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status?.toUpperCase() ?? 'UNKNOWN';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
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

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'submitted':
        return Icons.hourglass_top;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 80.0;
    final currentDate = _selectedDate ?? DateTime.now();
    final isToday = _isToday(currentDate);

    // Check if this is the latest version and it's rejected
    final isLatestVersion =
        _existingChecklist != null &&
        _allChecklists.isNotEmpty &&
        _existingChecklist!.id == _allChecklists.last.id;

    final isRejected = _existingChecklist?.status == 'rejected';

    // Only show resubmit in top-right if:
    // 1. It's the latest version
    // 2. It's rejected
    // 3. It's today
    final showResubmitInTopBar =
        isToday && !_isViewOnly && isLatestVersion && isRejected;

    // Show submit button if it's today, not view only, and not rejected (or no record)
    final showSubmitInTopBar = isToday && !_isViewOnly && !isRejected;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Bar
              Container(
                height: statusBarHeight + appBarHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: statusBarHeight),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Back Button
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.yellow[600],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                padding: const EdgeInsets.all(10),
                                iconSize: 24,
                                constraints: const BoxConstraints(),
                              ),
                            ),

                            // Title
                            Expanded(
                              child: Center(
                                child: Text(
                                  'CHECKLIST',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Submit/Resubmit Button
                            if (showResubmitInTopBar)
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isSubmitting
                                      ? Colors.grey
                                      : Colors.orange,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isSubmitting
                                                  ? Colors.grey
                                                  : Colors.orange)
                                              .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: _isSubmitting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : _resubmitChecklist,
                                  padding: const EdgeInsets.all(10),
                                  iconSize: 24,
                                  constraints: const BoxConstraints(),
                                ),
                              )
                            else if (showSubmitInTopBar)
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isSubmitting
                                      ? Colors.grey
                                      : Colors.green,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isSubmitting
                                                  ? Colors.grey
                                                  : Colors.green)
                                              .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: _isSubmitting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(Icons.check, color: Colors.white),
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitChecklist,
                                  padding: const EdgeInsets.all(10),
                                  iconSize: 24,
                                  constraints: const BoxConstraints(),
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Vehicle Reg No
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Text(
                  widget.vehicleRegNo,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Filter Row
              _buildFilterRow(),

              // Content
              Expanded(child: _buildContent()),
            ],
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildVersionChips() {
    if (_allChecklists.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allChecklists.length,
        itemBuilder: (context, index) {
          final checklist = _allChecklists[index];
          final version = checklist.version ?? index + 1;
          final isActive =
              _existingChecklist != null &&
              checklist.id == _existingChecklist?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                'v$version',
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: isActive
                  ? _getStatusColor(checklist.status)
                  : Colors.grey[800],
              side: BorderSide(
                color: _getStatusColor(checklist.status),
                width: 1,
              ),
              avatar: CircleAvatar(
                backgroundColor: isActive
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                radius: 12,
                child: Icon(
                  _getStatusIcon(checklist.status),
                  size: 12,
                  color: isActive
                      ? Colors.black
                      : _getStatusColor(checklist.status),
                ),
              ),
              onPressed: () {
                setState(() {
                  _existingChecklist = checklist;
                  _loadExistingChecklistData(checklist);
                  _isViewOnly = true;
                  _currentVersion = checklist.version ?? index + 1;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovedBySection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
                      _existingChecklist!.approvedBy?.name ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _existingChecklist!.approvedBy?.role.toUpperCase() ?? '',
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
                _getSriLankanTime(_existingChecklist!.updatedAt!),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          if (_existingChecklist!.comment != null &&
              _existingChecklist!.comment!.isNotEmpty) ...[
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
                _existingChecklist!.comment!,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionInfoSection() {
    // Check if this is the latest version and it's rejected
    final isLatestVersion =
        _existingChecklist != null &&
        _allChecklists.isNotEmpty &&
        _existingChecklist!.id == _allChecklists.last.id;

    final isRejected = _existingChecklist?.status == 'rejected';
    final isToday = _isToday(_selectedDate ?? DateTime.now());

    // Only show resubmit button if:
    // 1. It's the latest version
    // 2. It's rejected
    // 3. It's today
    final showResubmitButton = isLatestVersion && isRejected && isToday;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
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
                      _existingChecklist!.approvedBy?.name ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _existingChecklist!.approvedBy?.role.toUpperCase() ?? '',
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
                _getSriLankanTime(_existingChecklist!.updatedAt!),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          if (_existingChecklist!.comment != null &&
              _existingChecklist!.comment!.isNotEmpty) ...[
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _existingChecklist!.comment!,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
          // Resubmit button - only for latest rejected version on today
          if (showResubmitButton) ...[
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _resubmitChecklist,
                icon: Icon(Icons.refresh),
                label: Text('Resubmit Checklist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                  minimumSize: Size(double.infinity, 40),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ]
          else ...[
            SizedBox(height: 8,)
          ]
        ],
      ),
    );
  }

  String _getSriLankanTime(DateTime utcTime) {
    const sriLankanOffset = Duration(hours: 5, minutes: 30);
    final localTime = utcTime.add(sriLankanOffset);
    return DateFormat('hh:mm a').format(localTime);
  }

  Widget _buildFilterRow() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _setFilter('today'),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _currentFilter == 'today'
                      ? Color(0xFFF9C80E)
                      : Colors.grey[900],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: _currentFilter == 'today'
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _currentFilter == 'date'
                      ? Color(0xFFF9C80E)
                      : Colors.grey[900],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _currentFilter == 'date'
                          ? Colors.black
                          : Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM').format(_selectedDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _currentFilter == 'date'
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final currentDate = _selectedDate ?? DateTime.now();
    final isToday = _isToday(currentDate);

    if (_isLoading) {
      return Container();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (!_hasRecord && !isToday) {
      return _buildNoRecordView();
    }

    return _buildChecklistForm();
  }

  Widget _buildNoRecordView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.find_in_page, size: 60, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text(
            'No record found',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'No checklist available for this date',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistForm() {
    final currentDate = _selectedDate ?? DateTime.now();
    final checklistSections = _getChecklistSections();
    final isToday = _isToday(currentDate);

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Date Display with Status
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Color(0xFFF9C80E),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(currentDate),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_allChecklists.isNotEmpty) ...[
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'v${_existingChecklist?.version ?? _currentVersion}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Status Badge
                if (_hasRecord && _existingChecklist != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        _existingChecklist?.status,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getStatusColor(_existingChecklist?.status),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(_existingChecklist?.status),
                          size: 12,
                          color: _getStatusColor(_existingChecklist?.status),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getStatusText(_existingChecklist?.status),
                          style: TextStyle(
                            color: _getStatusColor(_existingChecklist?.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isToday)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFF9C80E).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xFFF9C80E)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 12, color: Color(0xFFF9C80E)),
                        SizedBox(width: 4),
                        Text(
                          'PENDING',
                          style: TextStyle(
                            color: Color(0xFFF9C80E),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Version Chips
          if (_allChecklists.isNotEmpty) _buildVersionChips(),

          // Status sections
          if (_existingChecklist?.status == 'approved' &&
              _existingChecklist?.approvedBy != null) ...[
            _buildApprovedBySection(),
          ],
          if (_existingChecklist?.status == 'rejected') ...[
            _buildRejectionInfoSection(),
          ],

          // Checklist Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var section in checklistSections.keys)
                    _buildChecklistSection(
                      section: section,
                      items: checklistSections[section]!,
                    ),

                  SizedBox(height: 8),

                  // Checked By Section
                  Container(
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
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Color(0xFFF9C80E),
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.userRole.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection({
    required String section,
    required List<String> items,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(section),
                  color: Color(0xFFF9C80E),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Checklist Items
          for (var item in items) _buildChecklistItem(item: item),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({required String item}) {
    final status = _checklistResponses[item]!['status'] as String? ?? '';
    final remarks = _checklistResponses[item]!['remarks'] as String? ?? '';
    final controller = _reasonControllers[item];

    // Initialize expanded state
    if (!_expandedItems.containsKey(item)) {
      _expandedItems[item] = false;
    }

    bool isExpanded = _expandedItems[item]!;
    bool isGood = status == 'good';
    bool isBad = status == 'bad';
    bool hasRemarks = remarks.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Item with Status buttons
          InkWell(
            onTap: () {
              setState(() {
                _expandedItems[item] = !isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isExpanded)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.comment,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  hasRemarks
                                      ? 'Has remarks (Click to view)'
                                      : !_isViewOnly
                                      ? 'Click to Add remarks (optional)'
                                      : 'No remarks',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  if (_isViewOnly)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGood
                            ? Colors.green.withOpacity(0.2)
                            : isBad
                            ? Colors.red.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isGood
                              ? Colors.green
                              : isBad
                              ? Colors.red
                              : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isGood
                                ? Icons.check
                                : isBad
                                ? Icons.close
                                : Icons.question_mark,
                            size: 12,
                            color: isGood
                                ? Colors.green
                                : isBad
                                ? Colors.red
                                : Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isGood
                                ? 'GOOD'
                                : isBad
                                ? 'BAD'
                                : 'NOT CHECKED',
                            style: TextStyle(
                              color: isGood
                                  ? Colors.green
                                  : isBad
                                  ? Colors.red
                                  : Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () => _updateChecklistItem(item, 'good'),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isGood
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isGood
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check,
                                color: isGood ? Colors.green : Colors.grey[400],
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 6),

                        InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () => _updateChecklistItem(item, 'bad'),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isBad
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isBad ? Colors.red : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close,
                                color: isBad ? Colors.red : Colors.grey[400],
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasRemarks && _isViewOnly)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        remarks,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  if (!_isViewOnly)
                    TextField(
                      controller: controller,
                      onChanged: (value) => _updateRemarks(item, value),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter remarks... (optional)',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey[600]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFFF9C80E)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabled: !_isViewOnly && !_isSubmitting,
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshChecklist,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF9C80E),
                foregroundColor: Colors.black,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFF9C80E)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFF9C80E)),
                SizedBox(height: 16),
                Text(
                  'Loading checklist...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
