import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/message_overlay.dart';

class AdminDashboardContent extends StatefulWidget {
  final User? user;

  const AdminDashboardContent({Key? key, required this.user}) : super(key: key);

  @override
  _AdminDashboardContentState createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  // Dashboard statistics data from API
  Map<String, dynamic> _dashboardStats = {};

  // Loading states
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Error message for user display
  String _errorMessage = '';

  // Timer for auto-refresh every 30 seconds
  Timer? _refreshTimer;

  // Report download states
  bool _isGeneratingReport = false;
  DateTime? _startDate;
  DateTime? _endDate;

  // Department filter states
  List<Department> _availableDepartments = [];
  String? _selectedDepartmentId; // null = all departments
  String? _tempSelectedDepartmentId; // For popup selection
  bool _isFilterPopupOpen = false;
  bool _isLoadingDepartments = false;

  @override
  void initState() {
    super.initState();
    // Initial data load with all departments
    _loadDashboardData();
    // Load departments for filter
    _loadDepartments();
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // Cancel timer to prevent memory leaks
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Loads departments for filter dropdown
  Future<void> _loadDepartments() async {
    if (_isLoadingDepartments) return;

    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final response = await ApiService.getUserDepartments(limit: 50);

      if (response['success'] == true) {
        final List<dynamic> departmentsData =
            response['data']['departments'] ?? [];
        setState(() {
          _availableDepartments = departmentsData
              .map((data) => Department.fromJson(data))
              .toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load departments');
      }
    } catch (e) {
      print('Error loading departments: $e');
      // Don't show error to user for department loading - just log it
    } finally {
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  /// Shows/hides the filter popup
  void _toggleFilterPopup() {
    setState(() {
      _isFilterPopupOpen = !_isFilterPopupOpen;
      // Initialize temp selection with current selection
      if (_isFilterPopupOpen) {
        _tempSelectedDepartmentId = _selectedDepartmentId;
      }
    });
  }

  /// Applies the selected filter
  void _applyFilter() {
    setState(() {
      _selectedDepartmentId = _tempSelectedDepartmentId;
      _isFilterPopupOpen = false;
    });
    // Reload dashboard data with selected filter
    _loadDashboardData();
  }

  /// Clears the filter (shows all departments)
  void _clearFilter() {
    setState(() {
      _selectedDepartmentId = null;
      _tempSelectedDepartmentId = null;
      _isFilterPopupOpen = false;
    });
    // Reload dashboard data without filter
    _loadDashboardData();
  }

  /// Gets the currently selected department name
  String? get _selectedDepartmentName {
    if (_selectedDepartmentId == null) return null;
    final department = _availableDepartments.firstWhere(
      (dept) => dept.id.toString() == _selectedDepartmentId,
      orElse: () => Department(
        id: 0,
        name: 'Unknown',
        isActive: true,
        employees: 0,
        headId: null,
        headName: null,
        costCenterId: null,
        costCenterName: null,
      ),
    );
    return department.name;
  }

  /// Starts auto-refresh timer that triggers every 30 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      // Only refresh if not already loading/refreshing
      if (!_isLoading) {
        _refreshDashboardSilently();
      }
    });
  }

  /// Main method to load dashboard data from API
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the API service to get dashboard statistics with department filter
      final response = await ApiService.getAdminDashboardStats(
        departmentId: _selectedDepartmentId,
      );

      if (response.isNotEmpty) {
        // Successfully received data from API
        setState(() {
          _dashboardStats = response;
        });
      } else {
        // API returned empty response
        setState(() {
          _errorMessage = 'No data available from server';
        });
      }
    } catch (e) {
      // Handle API call errors
      setState(() {
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
      print('Dashboard API Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Silent refresh that happens automatically every 30 seconds
  /// Doesn't show any loading indicators to user
  Future<void> _refreshDashboardSilently() async {
    // Don't start another refresh if one is already in progress
    if (_isRefreshing) return;

    // Set refreshing state but don't trigger UI rebuild
    _isRefreshing = true;

    try {
      final response = await ApiService.getAdminDashboardStats(
        departmentId: _selectedDepartmentId,
      );

      if (response.isNotEmpty) {
        // Update the data silently without triggering rebuild if data hasn't changed
        if (!_mapsAreEqual(response, _dashboardStats)) {
          // Only update if data has actually changed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _dashboardStats = response;
                // Clear any previous errors on successful refresh
                _errorMessage = '';
              });
            }
          });
        }
      }
    } catch (e) {
      // Don't show error on silent refresh - just log it
      print('Silent refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Helper function to compare two maps for equality
  bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (var key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      if (map1[key] != map2[key]) return false;
    }

    return true;
  }

  /// Manual refresh triggered by user pull-to-refresh
  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  /// Formats currency values with thousand separators and 2 decimal places
  String _formatCurrency(dynamic value) {
    // Convert value to double first
    final doubleValue = (value is int)
        ? value.toDouble()
        : (value ?? 0.0).toDouble();
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(doubleValue);
  }

  // Helper method to safely get double values from the stats map
  double _getDoubleValue(String key, [double defaultValue = 0.0]) {
    final value = _dashboardStats[key];
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper method to safely get int values from the stats map
  int _getIntValue(String key, [int defaultValue = 0]) {
    final value = _dashboardStats[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper method to get string values from the stats map
  String _getStringValue(String key, [String defaultValue = '']) {
    final value = _dashboardStats[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Builds the filter popup widget
  Widget _buildFilterPopup(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final popupWidth = isSmallScreen ? screenWidth * 0.9 : 320.0;

    return Positioned(
      top: 70, // Position below the title row
      left: (screenWidth - popupWidth) / 2,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: popupWidth,
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Filter by Department',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: _toggleFilterPopup,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Department Dropdown
              _buildDepartmentDropdownNew(
                currentDepartmentId: _tempSelectedDepartmentId ?? '',
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tempSelectedDepartmentId = value;
                    });
                  }
                },
              ),

              SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Show All'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Apply'),
                    ),
                  ),
                ],
              ),

              // Current filter info
              if (_selectedDepartmentId != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.blue),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Currently filtered by: ${_selectedDepartmentName ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Department Dropdown for the filter popup
  Widget _buildDepartmentDropdownNew({
    required String currentDepartmentId,
    required Function(String?) onChanged,
  }) {
    // Show loading indicator if departments are still loading
    if (_isLoadingDepartments) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Department',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 56,
            alignment: Alignment.center,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    // If no departments are available
    if (_availableDepartments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Department',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No departments available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    // Ensure the current value exists in available departments
    String? safeCurrentDepartmentId = currentDepartmentId.isNotEmpty
        ? currentDepartmentId
        : null;

    // Validate that the current selection exists in the list
    if (safeCurrentDepartmentId != null &&
        !_availableDepartments.any(
          (dept) => dept.id.toString() == safeCurrentDepartmentId,
        )) {
      safeCurrentDepartmentId = null;
    }

    // Create dropdown items including "All Departments" option
    final List<DropdownMenuItem<String>> dropdownItems = [
      ..._availableDepartments.map((department) {
        return DropdownMenuItem<String>(
          value: department.id.toString(),
          child: Text(department.name, style: TextStyle(color: Colors.black87)),
        );
      }).toList(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with Icon
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Department',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Dropdown
        DropdownButtonFormField<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          style: TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: 'Select Department',
            hintStyle: TextStyle(color: Colors.grey.shade600),
          ),
          value: safeCurrentDepartmentId,
          items: dropdownItems,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Shows the report download dialog
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.download, color: Colors.blue),
                SizedBox(width: 8),
                Text('Generate Report'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Fields
                  _buildDateField('From Date', _startDate, (date) {
                    setState(() {
                      _startDate = date;
                      // Reset end date if start date is cleared
                      if (date == null) {
                        _endDate = null;
                      } else if (_endDate != null && _endDate!.isBefore(date)) {
                        _endDate = null;
                      }
                    });
                  }, isStartDate: true),
                  SizedBox(height: 16),
                  _buildDateField('To Date', _endDate, (date) {
                    setState(() {
                      _endDate = date;
                    });
                  }, isStartDate: false),

                  SizedBox(height: 16),

                  // Selected Dates Summary
                  if (_startDate != null || _endDate != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Date Range:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Not set'} - ${_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Not set'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    _startDate != null &&
                        _endDate != null &&
                        !_endDate!.isBefore(_startDate!)
                    ? () {
                        Navigator.pop(context);
                        _showFormatSelectionDialog(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows format selection dialog (PDF/Excel)
  void _showFormatSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Report Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PDF Option
            _buildFormatOption(
              context,
              icon: Icons.picture_as_pdf,
              title: 'Download PDF Report',
              subtitle: 'Best for printing and viewing',
              color: Colors.red,
              format: 'pdf',
            ),
            SizedBox(height: 12),
            // Excel Option
            _buildFormatOption(
              context,
              icon: Icons.table_chart,
              title: 'Download Excel Report',
              subtitle: 'Best for data analysis',
              color: Colors.green,
              format: 'excel',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Builds a format option card
  Widget _buildFormatOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String format,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // First close the format selection dialog
          Navigator.pop(context);
          // Then start the download
          _downloadReport(format);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds date field widget similar to your example
  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime?) onDateSelected, {
    required bool isStartDate,
  }) {
    final bool isEnabled = isStartDate || _startDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: isEnabled
              ? () => _selectDate(
                  context,
                  onDateSelected,
                  isStartDate: isStartDate,
                )
              : null,
          child: Container(
            width: double.infinity,
            height: 45,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
              color: isEnabled ? Colors.white : Colors.grey.shade100,
            ),
            child: Row(
              children: [
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : isStartDate
                      ? 'Select start date'
                      : (_startDate == null
                            ? 'Select start date first'
                            : 'Select end date'),
                  style: TextStyle(
                    color: date != null
                        ? Colors.blue.shade800
                        : (isEnabled
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                if (date != null && isEnabled)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 18),
                    onPressed: () => onDateSelected(null),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                Icon(
                  Icons.calendar_today,
                  color: isEnabled
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Select date from date picker
  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime?) onDateSelected, {
    required bool isStartDate,
  }) async {
    final now = DateTime.now();
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate
        ? DateTime(now.year - 1)
        : (_startDate ?? DateTime(now.year - 1));
    final lastDate = now.add(Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  /// Downloads the report in specified format (PDF/Excel)

  Future<void> _downloadReport(String format) async {
    print('=== START _downloadReport for format: $format ===');

    if (_startDate == null || _endDate == null) {
      print('Error: Dates are null');
      _showErrorSnackBar('Please select both start and end dates');
      return;
    }

    print('Selected dates: $_startDate to $_endDate');

    if (_endDate!.isBefore(_startDate!)) {
      print('Error: End date before start date');
      _showErrorSnackBar('End date must be after the start date');
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    // Show downloading indicator
    final loadingSnackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Generating ${format.toUpperCase()} report...',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 30),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

    try {
      print('Starting API call...');
      print(
        'Params: fromDate=${_startDate}, toDate=${_endDate}, format=$format',
      );

      // Call API with timeout
      final fileBytes =
          await ApiService.downloadTripReport(
            fromDate: _startDate!,
            toDate: _endDate!,
            format: format,
          ).timeout(
            Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('Request timed out after 60 seconds');
            },
          );

      print('API call completed. File bytes: ${fileBytes?.length ?? 0} bytes');

      if (fileBytes != null && fileBytes.isNotEmpty) {
        print('File bytes received, proceeding with download...');

        // Generate file name with correct extension
        final extension = format == 'pdf' ? 'pdf' : 'xlsx';
        final fileName =
            'trip_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$extension';

        print('Downloading file: $fileName');

        // Platform-specific download
        if (kIsWeb) {
          // Web download using html package
          await _downloadFileWeb(fileBytes, fileName, format);
        } else {
          // Mobile download using path_provider
          await _downloadFileMobile(fileBytes, fileName, format);
        }

        // Reset dates after successful download
        setState(() {
          _startDate = null;
          _endDate = null;
        });
      } else {
        print('API returned null or empty file bytes');
        _showErrorSnackBar(
          'Report generation failed. The server returned an empty file.',
        );
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      _showErrorSnackBar(
        'Network connection error. Please check your internet connection and try again.',
      );
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      _showErrorSnackBar(
        'Request timed out. The server is taking too long to respond. Please try again later.',
      );
    } on HttpException catch (e) {
      print('HTTP error: $e');
      _showErrorSnackBar(
        'Server error (${e.message}). Please try again later or contact support.',
      );
    } on FormatException catch (e) {
      print('Format error: $e');
      _showErrorSnackBar(
        'Invalid data format received from server. Please contact support.',
      );
    } on PlatformException catch (e) {
      print('Platform error: $e');
      if (e.code == 'storage_permission_denied') {
        _showErrorSnackBar(
          'Storage permission denied. Please grant storage permission in app settings to save the report.',
        );
      } else {
        _showErrorSnackBar('Device error: ${e.message}');
      }
    } catch (e) {
      print('=== UNEXPECTED ERROR IN REPORT DOWNLOAD ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${e.toString()}');

      // Extract clean error message
      String errorMessage = e.toString();

      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      // Clean up any other prefixes
      errorMessage = errorMessage.replaceAll('Failed to download: ', '');
      errorMessage = errorMessage.replaceAll('Server error: ', '');

      // Check for specific error messages
      final lowerMessage = errorMessage.toLowerCase();

      if (lowerMessage.contains('no trips') ||
          lowerMessage.contains('no data') ||
          lowerMessage.contains('not found')) {
        _showErrorSnackBar(
          'No trip data found for the selected date range. Please select a different date range.',
        );
      } else if (lowerMessage.contains('invalid date') ||
          lowerMessage.contains('invalid range')) {
        _showErrorSnackBar(
          'Invalid date range selected. Please select valid dates.',
        );
      } else if (lowerMessage.contains('authentication failed') ||
          lowerMessage.contains('unauthorized')) {
        _showErrorSnackBar(
          'Authentication failed. Please log in again to generate reports.',
        );
      } else if (lowerMessage.contains('permission denied') ||
          lowerMessage.contains('forbidden')) {
        _showErrorSnackBar(
          'You do not have permission to generate reports. Contact your administrator.',
        );
      } else if (lowerMessage.contains('server error')) {
        _showErrorSnackBar(
          'Server error occurred while generating report. Please try again later.',
        );
      } else if (lowerMessage.contains('invalid request')) {
        _showErrorSnackBar(
          'Invalid request. Please check your selections and try again.',
        );
      } else {
        // Show the clean error message
        if (errorMessage.length > 100) {
          _showErrorSnackBar('Failed to generate report. Please try again.');
        } else {
          _showErrorSnackBar('Error: $errorMessage');
        }
      }
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });

      print('=== END _downloadReport ===');

      // Clear the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show completion message if not already showing an error
      if (!_isGeneratingReport && ScaffoldMessenger.of(context).mounted) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  // Add this new method for web download
  Future<void> _downloadFileWeb(
    Uint8List fileBytes,
    String fileName,
    String format,
  ) async {
    try {
      print('Starting web download for: $fileName');

      // Create a blob from the bytes
      final blob = html.Blob([fileBytes], 'application/octet-stream');

      // Determine MIME type based on format
      final mimeType = format == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      final blobWithType = html.Blob([fileBytes], mimeType);

      // Create a URL for the blob
      final url = html.Url.createObjectUrlFromBlob(blobWithType);

      // Create an anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      // Clean up the URL after download
      html.Url.revokeObjectUrl(url);

      print('Web download completed successfully');

      // Show success message
      if (mounted) {
        MessageOverlay.showSuccess(
          context: context,
          message: 'Report downloaded successfully: $fileName',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: const Duration(seconds: 2),
          onComplete: () {
            // You might want to trigger a refresh here
          },
        );
      }
    } catch (e) {
      print('Error in web download: $e');

      // Fallback: Use data URL for download
      try {
        final mimeType = format == 'pdf'
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

        final base64Data = base64Encode(fileBytes);
        final dataUrl = 'data:$mimeType;base64,$base64Data';

        final anchor = html.AnchorElement(href: dataUrl)
          ..setAttribute('download', fileName)
          ..click();

        print('Web download completed using data URL fallback');
      } catch (fallbackError) {
        print('Fallback download also failed: $fallbackError');
        throw Exception('Failed to download file on web platform');
      }
    }
  }

  /// Shows error snackbar with better styling
  void _showErrorSnackBar(String message) {
    // Clear any existing snackbars first
    /*
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    */

    MessageOverlay.showError(
      context: context,
      message: message,
      position: OverlayPosition.top,
      showBackgroundOverlay: true,
      showOkButton: true,
    );
  }

  /// Shows success snackbar with better styling
  void _showSuccessSnackBar(String message) {
    // Clear any existing snackbars first
    /*
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    */

    MessageOverlay.showSuccess(
      context: context,
      message: message,
      position: OverlayPosition.top,
      showBackgroundOverlay: true,
      duration: const Duration(seconds: 2),
      onComplete: () {
        // You might want to trigger a refresh here
      },
    );
  }

  // Mobile download using path_provider
  Future<void> _downloadFileMobile(
    Uint8List bytes,
    String fileName,
    String format,
  ) async {
    try {
      print('Starting mobile download for file: $fileName');

      // Get the downloads directory (preferred) or documents directory
      Directory? directory;

      try {
        // Try to get external storage (downloads folder)
        directory = await getExternalStorageDirectory();
        if (directory == null) {
          print('External storage not available, using documents directory');
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        print('Error getting external storage: $e, using documents directory');
        directory = await getApplicationDocumentsDirectory();
      }

      // Create file path
      final filePath = '${directory!.path}/$fileName';
      print('Saving file to: $filePath');

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      print('File saved successfully. File size: ${file.lengthSync()} bytes');

      // Try to open the file
      print('Attempting to open file...');
      final openResult = await OpenFile.open(filePath);
      print('Open file result: ${openResult.type}');

      if (openResult.type == ResultType.done) {
        _showSuccessSnackBar('Report downloaded and opened successfully!');
      } else if (openResult.type == ResultType.noAppToOpen) {
        _showSuccessSnackBar(
          'Report saved to: $filePath\n(No app found to open this file type)',
        );
      } else if (openResult.type == ResultType.fileNotFound) {
        _showErrorSnackBar('Error: File not found at $filePath');
      } else if (openResult.type == ResultType.permissionDenied) {
        _showErrorSnackBar('Permission denied to open the file');
      } else {
        _showSuccessSnackBar('Report saved to: $filePath');
      }
    } catch (e) {
      print('Error in mobile download: $e');

      // Try alternative location
      try {
        print('Trying alternative location...');
        final tempDir = await getTemporaryDirectory();
        final fallbackPath = '${tempDir.path}/$fileName';
        final file = File(fallbackPath);
        await file.writeAsBytes(bytes);
        _showSuccessSnackBar('Report saved to temporary folder: $fileName');
      } catch (e2) {
        print('Alternative also failed: $e2');
        _showErrorSnackBar(
          'Failed to save file. Please check storage permissions.',
        );
      }
    }
  }

  /// Calculates aspect ratio for grid cards based on screen width
  /// Ensures proper card proportions on different screen sizes
  double _calculateCardAspectRatio(double screenWidth) {
    if (screenWidth > 1200) return 1.8;
    if (screenWidth > 800) return 1.6;
    if (screenWidth > 600) return 1.4;
    if (screenWidth > 400) return 1.3;
    return 1.2;
  }

  /// Builds a single statistic card with responsive design
  Widget _buildDynamicStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    double screenWidth,
  ) {
    // Responsive sizing based on screen width
    final bool isVerySmall = screenWidth < 320;
    final double iconSize = isVerySmall ? 12 : (screenWidth < 360 ? 14 : 16);
    final double valueFontSize = isVerySmall
        ? 14
        : (screenWidth < 360 ? 16 : 18);
    final double titleFontSize = isVerySmall
        ? 10
        : (screenWidth < 360 ? 11 : 12);
    final double subtitleFontSize = isVerySmall
        ? 8
        : (screenWidth < 360 ? 9 : 10);

    return Container(
      constraints: BoxConstraints(minHeight: 80, maxHeight: 120),
      padding: EdgeInsets.all(screenWidth < 360 ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container at top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth < 360 ? 4 : 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                ],
              ),

              // Main content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Value (main number) with responsive scaling
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(height: 4),

                    // Title (description)
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Subtitle (additional info) - only shows if there's space
              if (subtitle.isNotEmpty && constraints.maxHeight > 70)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;

    // Check if user is allowed to see report button
    final showReportButton =
        widget.user?.role == UserRole.sysadmin ||
        widget.user?.role == UserRole.hr;

    // Get dashboard title from API response or use default
    final dashboardTitle = _getStringValue('dashboardTitle').isNotEmpty
        ? _getStringValue('dashboardTitle')
        : (widget.user?.role == UserRole.sysadmin
              ? 'All Departments'
              : 'Dashboard');

    // Show loading indicator for initial load only
    if (_isLoading && !_isRefreshing) {
      return Center(child: CircularProgressIndicator());
    }

    // Show error screen if there's an error and no data
    if (_errorMessage.isNotEmpty && _dashboardStats.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Unable to Load Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: Text('Retry Loading'),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate derived values for UI using safe getters
    final double budgetAmount = _getDoubleValue('budgetAmount');
    final double actualCost = _getDoubleValue('actualCost');

    final double budgetVsActual = (budgetAmount > 0)
        ? (actualCost / budgetAmount) * 100
        : 0.0;

    final bool isOverBudget = actualCost > budgetAmount;

    final double monthOverMonthChange = _getDoubleValue('monthOverMonthChange');
    final bool isCostIncrease = monthOverMonthChange > 0;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Dashboard Title with Department Name and Filter Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Filter indicator icon (shown when filter is active)
                                if (_selectedDepartmentId != null)
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.filter_alt,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    '${dashboardTitle} Usage',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            // Show filtered department name if a filter is applied
                            if (_selectedDepartmentId != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${_selectedDepartmentName ?? 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Filter Button
                      IconButton(
                        onPressed: _toggleFilterPopup,
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedDepartmentId != null
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.filter_alt,
                            size: isSmallScreen ? 18 : 20,
                            color: _selectedDepartmentId != null
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                        ),
                        tooltip: 'Filter by Department',
                      ),
                    ],
                  ),
                ),
              ),

              // Error banner (shows at top if there's an error with existing data)
              if (_errorMessage.isNotEmpty && _dashboardStats.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 8,
                    ),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.orange[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 16),
                          onPressed: _refreshDashboard,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),

              // Main Statistics Cards Grid - Responsive layout
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  4,
                  isSmallScreen ? 12 : 16,
                  16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : (isSmallScreen ? 2 : 2),
                    crossAxisSpacing: isSmallScreen ? 8 : 12,
                    mainAxisSpacing: isSmallScreen ? 8 : 12,
                    childAspectRatio: _calculateCardAspectRatio(screenWidth),
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Build different stat cards based on index
                    switch (index) {
                      case 0: // Total Rides
                        return _buildDynamicStatCard(
                          'Total Rides',
                          '${_getIntValue('totalRides')}',
                          Icons.directions_car,
                          Colors.blue,
                          'Completed Rides',
                          screenWidth,
                        );
                      case 1: // Pending for Supervisor
                        return _buildDynamicStatCard(
                          'Pending for Supervisor',
                          '${_getIntValue('pendingSupervisorRides')}',
                          Icons.pending_actions,
                          Colors.orange,
                          'Draft rides',
                          screenWidth,
                        );
                      case 2: // Today's Rides
                        return _buildDynamicStatCard(
                          "Today's Rides",
                          '${_getIntValue('ridesToday')}',
                          Icons.today,
                          Colors.purple,
                          'Scheduled for today',
                          screenWidth,
                        );
                      case 3: // Monthly Cost
                        return _buildDynamicStatCard(
                          'Monthly Cost',
                          'LKR ${_formatCurrency(_getDoubleValue('currentMonthCost'))}',
                          Icons.attach_money,
                          Colors.teal,
                          'Current month',
                          screenWidth,
                        );
                      case 4: // Total Users
                        return _buildDynamicStatCard(
                          'Total Users',
                          '${_getIntValue('totalUsers')}',
                          Icons.people,
                          Colors.green,
                          'Approved',
                          screenWidth,
                        );
                      case 5: // Pending Users
                        return _buildDynamicStatCard(
                          'Pending Users',
                          '${_getIntValue('pendingUserCreations')}',
                          Icons.person_add,
                          Colors.red,
                          'Awaiting approval',
                          screenWidth,
                        );
                      default:
                        return SizedBox.shrink();
                    }
                  }, childCount: 6),
                ),
              ),

              // Budget vs Actual Performance Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Performance',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedDepartmentId == null
                            ? 'All Departments'
                            : _selectedDepartmentName ?? 'Selected Department',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isVeryNarrow =
                                constraints.maxWidth < 300;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section title
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Budget vs Actual',
                                      style: TextStyle(
                                        fontSize: isVeryNarrow ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _selectedDepartmentId == null
                                          ? 'All Departments'
                                          : _selectedDepartmentName ??
                                                'Selected Department',
                                      style: TextStyle(
                                        fontSize: isVeryNarrow ? 12 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),

                                // Variance percentage badge
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 120,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOverBudget
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isOverBudget
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            size: 14,
                                            color: isOverBudget
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              '${(_getDoubleValue('costVariancePercent')).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isOverBudget
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Progress bar showing budget vs actual
                                LinearProgressIndicator(
                                  value: budgetVsActual / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget ? Colors.red : Colors.green,
                                  ),
                                  minHeight: isVeryNarrow ? 10 : 12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                SizedBox(height: 12),

                                // Budget and Actual cost values
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isVeryNarrow)
                                      // Horizontal layout for wider screens
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Budget',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'LKR ${_formatCurrency(budgetAmount)}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Actual Cost',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'LKR ${_formatCurrency(actualCost)}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOverBudget
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      // Vertical layout for narrow screens
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Budget',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'LKR ${_formatCurrency(budgetAmount)}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Actual Cost',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'LKR ${_formatCurrency(actualCost)}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOverBudget
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 16),
                                    Divider(),
                                    SizedBox(height: 12),

                                    // Variance amount and status
                                    if (!isVeryNarrow)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Variance',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'LKR ${_formatCurrency((_getDoubleValue('costVariance')).abs())}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: isOverBudget
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isOverBudget
                                                        ? Colors.red
                                                              .withOpacity(0.1)
                                                        : Colors.green
                                                              .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isOverBudget
                                                        ? 'Over Budget'
                                                        : 'Under Budget',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: isOverBudget
                                                          ? Colors.red
                                                          : Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Variance',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'LKR ${_formatCurrency((_getDoubleValue('costVariance')).abs())}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isOverBudget
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isOverBudget
                                                      ? Colors.red.withOpacity(
                                                          0.1,
                                                        )
                                                      : Colors.green
                                                            .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isOverBudget
                                                      ? 'Over Budget'
                                                      : 'Under Budget',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isOverBudget
                                                        ? Colors.red
                                                        : Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Month-over-Month Cost Comparison Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: 8,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header with icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bar_chart,
                                color: Colors.blue,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cost Comparison (Month-over-Month)',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _selectedDepartmentId == null
                                        ? 'All Departments'
                                        : _selectedDepartmentName ??
                                              'Selected Department',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Cost comparison details
                        Column(
                          children: [
                            // Previous Month Cost
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Previous Month:',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'LKR ${_formatCurrency(_getDoubleValue('previousMonthCost'))}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Current Month Cost
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Current Month:',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'LKR ${_formatCurrency(_getDoubleValue('currentMonthCost'))}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Month-over-Month Change Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Change:',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      isCostIncrease
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: isCostIncrease
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'LKR ${_formatCurrency((monthOverMonthChange).abs())}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 15,
                                        fontWeight: FontWeight.w600,
                                        color: isCostIncrease
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Percentage Change with colored background
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Percentage Change:',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCostIncrease
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCostIncrease
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 12,
                                        color: isCostIncrease
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${(_getDoubleValue('monthOverMonthPercent')).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: isCostIncrease
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Trend indicator badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCostIncrease
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCostIncrease
                                          ? Colors.red.withOpacity(0.3)
                                          : Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCostIncrease
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        size: 14,
                                        color: isCostIncrease
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        isCostIncrease
                                            ? 'Cost Increased'
                                            : 'Cost Decreased',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: isCostIncrease
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // QUICK ACTIONS SECTION - Only for sysadmin and hr
              if (showReportButton)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        SizedBox(height: 8),
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Report Download Card
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showReportDialog(context),
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 8 : 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.download,
                                      color: Colors.blue,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trip Details',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Generate PDF/Excel reports for trips',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Extra space at bottom for better scrolling
              SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),

        // Filter Popup (shown on top when opened)
        if (_isFilterPopupOpen) _buildFilterPopup(context),
      ],
    );
  }
}
