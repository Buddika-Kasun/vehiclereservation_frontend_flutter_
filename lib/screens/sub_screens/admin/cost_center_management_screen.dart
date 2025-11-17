import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/costCenter_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class CostCenterManagementScreen extends StatefulWidget {
  const CostCenterManagementScreen({Key? key}) : super(key: key);

  @override
  _CostCenterManagementScreenState createState() => _CostCenterManagementScreenState();
}

class _CostCenterManagementScreenState extends State<CostCenterManagementScreen> {
  List<CostCenter> _costCenters = [];
  int? _expandedIndex;
  bool _isLoading = true;
  bool _hasCompany = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCompanyAndLoadCostCenters();
  }

  Future<void> _checkCompanyAndLoadCostCenters() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // First check if company exists
      final companyResponse = await ApiService.getCompanyStatus();
      
      if (companyResponse['success'] == true) {
        setState(() {
          _hasCompany = companyResponse['data'] ?? false;
        });

        if (_hasCompany) {
          // Load cost centers only if company exists
          await _loadCostCenters();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        throw Exception(companyResponse['message'] ?? 'Failed to check company status');
      }
    } catch (e) {
      print('Error checking company: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCostCenters() async {
    try {
      final response = await ApiService.getCostCenters();
      
      if (response['success'] == true) {
        final List<dynamic> costCentersData = response['data']['costCenters'] ?? [];
        setState(() {
          _costCenters = costCentersData.map((data) => CostCenter.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load cost centers');
      }
    } catch (e) {
      print('Error loading cost centers: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createCostCenter(CostCenter costCenter) async {
    try {
      final response = await ApiService.createCostCenter(costCenter.toJson());
      
      if (response['success'] == true) {
        await _loadCostCenters();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cost Center created successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create cost center');
      }
    } catch (e) {
      print('Error creating cost center: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create cost center: $e')),
      );
      rethrow;
    }
  }

  Future<void> _updateCostCenter(CostCenter costCenter) async {
    try {
      final response = await ApiService.updateCostCenter(costCenter.id, costCenter.toJson());
      
      if (response['success'] == true) {
        await _loadCostCenters();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cost Center updated successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update cost center');
      }
    } catch (e) {
      print('Error updating cost center: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update cost center: $e')),
      );
      rethrow;
    }
  }

  Future<void> _deleteCostCenter(int id, int index) async {
    try {
      final response = await ApiService.deleteCostCenter(id);
      
      if (response['success'] == true) {
        setState(() {
          _costCenters.removeAt(index);
          _expandedIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cost Center deleted successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete cost center');
      }
    } catch (e) {
      print('Error deleting cost center: $e');
      _expandedIndex = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete cost center: $e')),
      );
      //rethrow;
    }
  }

  String _generateShortName(String costCenterName) {
    if (costCenterName.isEmpty) return 'CC';
    final words = costCenterName.split(' ');
    final initials = words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _isLoading
          ? _buildLoading()
          : _hasError
              ? _buildErrorWidget()
              : !_hasCompany
                  ? _buildNoCompanyWidget()
                  : _buildMainContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkCompanyAndLoadCostCenters,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCompanyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Company Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You need to create a company before managing cost centers.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to company creation screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateCompanyScreen()));
              },
              icon: Icon(Icons.add_business),
              label: Text('Create Company'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost Centers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Create New Button
        Padding(
          padding: EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showCreateCostCenterDialog,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create New',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 8),
        
        // Available Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _costCenters.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Cost Centers List
        Expanded(
          child: _costCenters.isEmpty 
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCostCenters,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _costCenters.length,
                    itemBuilder: (context, index) {
                      final costCenter = _costCenters[index];
                      final isExpanded = _expandedIndex == index;
                      final shortName = _generateShortName(costCenter.name);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ColorGenerator.getRandomColor(costCenter.name).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: isExpanded 
                                    ? Border.all(color: ColorGenerator.getRandomColor(costCenter.name).withOpacity(0.2), width: 2)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      // Cost Center Icon
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: ColorGenerator.getRandomColor(costCenter.name),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            shortName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      
                                      // Cost Center Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                                Text(
                                                  costCenter.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'Budget: \$${costCenter.budget.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            
                                        )
                                      ),
                                      
                                      // Expand/Collapse Arrow
                                      Transform.rotate(
                                        angle: isExpanded ? -1.5708 : 1.5708,
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Expanded Details
                                  if (isExpanded) ...[
                                    SizedBox(height: 16),
                                    Divider(height: 1, color: Colors.grey[300]),
                                    SizedBox(height: 16),
                                    
                                    // Details Grid
                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          icon: Icons.account_balance_wallet,
                                          title: 'Allocated Budget',
                                          value: '\$${costCenter.budget.toStringAsFixed(2)}',
                                        ),
                                        SizedBox(width: 24),
                                        _buildDetailItem(
                                          icon: Icons.circle,
                                          title: 'Status',
                                          value: costCenter.isActive ? 'Active' : 'Inactive',
                                          valueColor: costCenter.isActive ? Colors.green : Colors.orange,
                                        ),
                                      ],
                                    ),
                            
                                    SizedBox(height: 20),

                                    Row(
                                      children: [
                                        _buildDetailItem(
                                          icon: Icons.calendar_today,
                                          title: 'Created At',
                                          value: costCenter.createdAt?.toIso8601String().split('T').first ?? 'N/A',
                                        ),
                                        SizedBox(width: 24),
                                        _buildDetailItem(
                                          icon: Icons.update,
                                          title: 'Updated At',
                                          value: costCenter.updatedAt?.toIso8601String().split('T').first ?? 'N/A',
                                        )
                                      ],
                                    ),
                                          
                                    
                                    SizedBox(height: 16),
                                    
                                    // Action Buttons
                                    Row(
                                      children: [
                                        // Edit Button
                                        Expanded(
                                          child: Container(
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.secondary.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () {
                                                  _showEditCostCenterDialog(index, costCenter);
                                                },
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Edit Cost Center',
                                                        style: TextStyle(
                                                          color: AppColors.primary,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        
                                        // Delete Button
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () {
                                                _showDeleteConfirmation(index);
                                              },
                                              child: Center(
                                                child: Icon(Icons.delete, color: Colors.white, size: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Cost Center Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your cost center to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          /*ElevatedButton(
            onPressed: _showCreateCostCenterDialog,
            child: Text('Create Cost Center'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.black87,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCostCenterDialog() {
    String name = '';
    double budget = 0.0;
    bool isActive = true;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'New Cost Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Cost Center Name *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.yellow),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'e.g., HR-001',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Allocated Budget *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.yellow),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'e.g., 10000.00',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => budget = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active Cost Center",
                            style: TextStyle(color: Colors.white, fontSize: 16)
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            onChanged: (bool value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                            inactiveTrackColor: Colors.transparent,
                            inactiveThumbColor: Colors.yellow.shade600,
                            activeColor: Colors.yellow[600],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () => Navigator.pop(context),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () async {
                                if (name.isNotEmpty && budget > 0) {
                                  try {
                                    setState(() {
                                      _isSubmitting = true;
                                    });

                                    final newCostCenter = CostCenter(
                                      id: 0, 
                                      name: name, 
                                      budget: budget, 
                                      isActive: isActive
                                    );

                                    await _createCostCenter(newCostCenter);

                                    Navigator.pop(context);
                                  } catch (e) {
                                    setState(() {
                                      _isSubmitting = false;
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please fill all required fields')),
                                  );
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        'Create',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditCostCenterDialog(int index, CostCenter costCenter) {
    String name = costCenter.name;
    double budget = costCenter.budget;
    bool isActive = costCenter.isActive;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'Edit Cost Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: TextEditingController(text: name),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Cost Center Name *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.yellow),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: TextEditingController(text: budget.toStringAsFixed(2)),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Allocated Budget *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.yellow),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.yellow, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => budget = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active Cost Center",
                            style: TextStyle(color: Colors.white, fontSize: 16)
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            onChanged: (bool value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                            inactiveTrackColor: Colors.transparent,
                            inactiveThumbColor: Colors.yellow.shade600,
                            activeColor: Colors.yellow[600],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () => Navigator.pop(context),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () async {
                                try {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  final updateCostCenter = CostCenter(
                                    id: _costCenters[index].id,
                                    name: name, 
                                    budget: budget, 
                                    isActive: isActive
                                  );

                                  await _updateCostCenter(
                                    updateCostCenter
                                  );

                                  Navigator.pop(context);
                                } catch (e) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'Delete Cost Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Are you sure you want to delete ${_costCenters[index].name} cost center?',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () => Navigator.pop(context),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSubmitting ? [] : [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isSubmitting ? null : () async {
                                try {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  await _deleteCostCenter(_costCenters[index].id, index);
                                  Navigator.pop(context);
                                } catch (e) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}