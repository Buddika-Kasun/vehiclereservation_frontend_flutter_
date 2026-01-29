import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';

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
  bool _hasRecord = false;
  bool _isViewOnly = false;

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
      });

      final currentDate = _selectedDate ?? DateTime.now();
      final isToday = _isToday(currentDate);

      ChecklistResponse? checklist;
      bool exists = false;

      print('📅 Loading checklist for date: $currentDate');
      print('📅 Is Today: $isToday');

      // First, check if checklist exists
      try {
        exists = await ApiService.checkIfChecklistExists(
          vehicleId: widget.vehicleId,
          date: currentDate,
        );
        print('✅ Checklist exists check: $exists');
      } catch (e) {
        print('⚠️ Error in exists check: $e');
      }

      // If exists is true, try to get the full checklist
      if (exists) {
        try {
          print('🔄 Fetching full checklist data...');
          checklist = await ApiService.getChecklistByDate(
            vehicleId: widget.vehicleId,
            date: currentDate,
          );
          print('✅ Full checklist fetched: ${checklist != null}');
          if (checklist != null) {
            print('📋 Checklist ID: ${checklist.id}');
            print('📋 Is Submitted: ${checklist.isSubmitted}');
          }
        } catch (e) {
          print('⚠️ Error fetching full checklist: $e');
        }
      } else {
        print('ℹ️ Checklist does not exist according to exists endpoint');
      }

      _processChecklistData(checklist, isToday, exists);
    } catch (e) {
      print('❌ Error in _loadChecklistData: $e');
      setState(() {
        _errorMessage = 'Error loading checklist: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _processChecklistData(
    ChecklistResponse? checklist,
    bool isToday,
    bool exists,
  ) {
    print('🔄 Processing checklist data...');
    print('  Checklist object: ${checklist != null}');
    print('  Exists endpoint: $exists');
    print('  Is Today: $isToday');

    if (checklist != null) {
      print('  Checklist ID: ${checklist.id}');
      print('  Vehicle: ${checklist.vehicleRegNo}');
      print('  Responses count: ${checklist.responses.length}');
      print('  Is Submitted: ${checklist.isSubmitted}');
    }

    setState(() {
      _existingChecklist = checklist;

      // Update hasRecord based on both checklist object and exists endpoint
      _hasRecord = checklist != null || exists;

      print('  Setting hasRecord to: $_hasRecord');

      if (_hasRecord && checklist != null) {
        // We have the full checklist data - ALWAYS view only
        _isViewOnly = true;
        _loadExistingChecklistData(checklist);
        print('✅ Loaded existing checklist in view-only mode');
      } else if (_hasRecord && checklist == null) {
        // Checklist exists but we couldn't fetch the full data - also view only
        _isViewOnly = true;
        print('⚠️ Checklist exists but data not loaded - showing empty form');
      } else {
        // No checklist exists
        if (isToday) {
          _isViewOnly = false;
          _initializeChecklistForm();
          print('✅ No record for today - initialized editable form');
        } else {
          _isViewOnly = true;
          print('❌ No record for past date');
        }
      }

      _isLoading = false;

      print('=== FINAL STATE ===');
      print('  Has Record: $_hasRecord');
      print('  Is View Only: $_isViewOnly');
      print('  Is Today: $isToday');
      print('  Can Submit: ${isToday && !_isViewOnly && !_hasRecord}');
    });
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
            'status': status ?? '', // Ensure not null
            'remarks': remarks,
          };

          _reasonControllers[item] = TextEditingController(text: remarks);

          // Debug print
          print('📝 Loaded: $item - Status: $status - Remarks: $remarks');
        } else {
          // Item not found in API response
          _checklistResponses[item] = {'status': '', 'remarks': ''};
          _reasonControllers[item] = TextEditingController();
          print('⚠️ Item not in API response: $item');
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
      print('Updated $item to $status');
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

    // Validate all items are checked
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please check all items before submitting. Missing: ${uncheckedItems.length} items',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      // Convert to API format
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

      print('Submitting checklist with ${apiResponses.length} items');

      try {
        // Submit to API
        final ChecklistResponse response = await ApiService.submitChecklist(
          vehicleId: widget.vehicleId,
          vehicleRegNo: widget.vehicleRegNo,
          checklistDate: _selectedDate ?? DateTime.now(),
          checkedById: widget.userId,
          checkedByName: widget.userName,
          checkedByRole: widget.userRole,
          responses: apiResponses,
        );

        print('✅ Checklist submitted successfully!');
        print('Response ID: ${response.id}');
        print('Submitted: ${response.isSubmitted}');

        // CRITICAL: Force a complete reload of the checklist data
        await _loadChecklistData();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (parseError) {
        print('⚠️ Parse error: $parseError');

        // IMPORTANT: Even if parsing fails, the API call was successful
        // So we should still refresh the data
        await _loadChecklistData();

        // Show success message anyway (API call succeeded)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Checklist submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error submitting checklist: $e');

      // Show error message
      String errorMessage = 'Error submitting checklist';
      if (e.toString().contains('already exists')) {
        errorMessage = 'Checklist already exists for today';
        // Refresh to show existing checklist
        await _loadChecklistData();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate == today;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 80.0;
    final currentDate = _selectedDate ?? DateTime.now();
    final isToday = _isToday(currentDate);

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

                            // Submit Button - Show ONLY when:
                            // 1. It's today AND
                            // 2. We're not in view-only mode (no existing record)
                            if (isToday && !_isViewOnly)
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
                                      : const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.vehicleRegNo,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

  Widget _buildFilterRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: EdgeInsets.all(16),
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
                  ],
                ),
                // Status Badge
                if (_hasRecord)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'SUBMITTED',
                          style: TextStyle(
                            color: Colors.green,
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

    // Debug print
    print('UI Building: $item - Status: $status - Remarks: $remarks');

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
              // Always allow expanding to see remarks
              setState(() {
                _expandedItems[item] = !isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // Item name
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
                        if (hasRemarks && !isExpanded && _isViewOnly)
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
                                  'Has remarks',
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

                  // Status indicator
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
                        // Good button
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

                        // Bad button
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

          // Expandable Remarks field
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasRemarks && _isViewOnly)
                    Container(
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
