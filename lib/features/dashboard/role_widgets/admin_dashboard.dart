import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class AdminDashboardContent extends StatefulWidget {
  final User? user;
  final Map<String, dynamic>? stats;

  const AdminDashboardContent({Key? key, required this.user, this.stats})
    : super(key: key);

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

  @override
  void initState() {
    super.initState();
    // Initial data load
    _loadDashboardData();
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // Cancel timer to prevent memory leaks
    _refreshTimer?.cancel();
    super.dispose();
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
      // Call the API service to get dashboard statistics
      final response = await ApiService.getAdminDashboardStats();

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
      final response = await ApiService.getAdminDashboardStats();

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;

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

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
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
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: 16,
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
                        final bool isVeryNarrow = constraints.maxWidth < 300;
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
                                  'All cost centers',
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
                                  constraints: BoxConstraints(maxWidth: 120),
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
                                              overflow: TextOverflow.ellipsis,
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
                                              overflow: TextOverflow.ellipsis,
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
                                              overflow: TextOverflow.ellipsis,
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
                                                    ? Colors.red.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.green.withOpacity(
                                                        0.1,
                                                      ),
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
                                                overflow: TextOverflow.ellipsis,
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
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(
                                                      0.1,
                                                    ),
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
                                              overflow: TextOverflow.ellipsis,
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

          // Extra space at bottom for better scrolling
          SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
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

}
