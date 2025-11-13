import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class CostCenterManagementScreen extends StatefulWidget {
  const CostCenterManagementScreen({Key? key}) : super(key: key);

  @override
  _CostCenterManagementScreenState createState() => _CostCenterManagementScreenState();
}

class _CostCenterManagementScreenState extends State<CostCenterManagementScreen> {
  //List<CostCenter> _costCenters = []; // Initialize as empty list
  List<CostCenter> _costCenters = [
    CostCenter(name: 'HR-001', allocatedBudget: 15000.00, isActive: true),
    CostCenter(name: 'IT-002', allocatedBudget: 25000.00, isActive: false),
    CostCenter(name: 'FIN-003', allocatedBudget: 30000.00, isActive: true),
  ];

  int? _expandedIndex;

  String _generateShortName(String costCenterName) {
    if (costCenterName.isEmpty) return 'CC';
    // Get first letter of each word and capitalize
    final words = costCenterName.split(' ');
    final initials = words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
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
                  onTap: () {
                    _showCreateCostCenterDialog();
                  },
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
                : ListView.builder(
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
                                        'Budget: \$${costCenter.allocatedBudget.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
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
                                    value: '\$${costCenter.allocatedBudget.toStringAsFixed(2)}',
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
        ],
      ),
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
    double allocatedBudget = 0.0;
    bool isActive = true;

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
                  // Title
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

                  // Cost Center Name Field
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

                  // Allocated Budget Field
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
                    onChanged: (value) => allocatedBudget = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
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

                  // Buttons Row
                  Row(
                    children: [
                      // Cancel Button
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
                              onTap: () => Navigator.pop(context),
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
                      
                      // Create Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
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
                              onTap: () {
                                if (name.isNotEmpty && allocatedBudget > 0) {
                                  final newCostCenter = CostCenter(
                                    name: name,
                                    allocatedBudget: allocatedBudget,
                                    isActive: isActive,
                                  );
                                  setState(() {
                                    _costCenters.add(newCostCenter);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Cost Center created successfully')),
                                  );
                                }
                              },
                              child: Center(
                                child: Text(
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
    double allocatedBudget = costCenter.allocatedBudget;
    bool isActive = costCenter.isActive;

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
                  // Title
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

                  // Cost Center Name Field
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

                  // Allocated Budget Field
                  TextField(
                    controller: TextEditingController(text: allocatedBudget.toStringAsFixed(2)),
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
                    onChanged: (value) => allocatedBudget = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
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

                  // Buttons Row
                  Row(
                    children: [
                      // Cancel Button
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
                              onTap: () => Navigator.pop(context),
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
                      
                      // Save Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
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
                              onTap: () {
                                final updatedCostCenter = CostCenter(
                                  name: name,
                                  allocatedBudget: allocatedBudget,
                                  isActive: isActive,
                                );
                                setState(() {
                                  _costCenters[index] = updatedCostCenter;
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cost Center updated successfully')),
                                );
                              },
                              child: Center(
                                child: Text(
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              // Title
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

              // Content
              Text(
                'Are you sure you want to delete ${_costCenters[index].name} cost center?',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons Row
              Row(
                children: [
                  // Cancel Button
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
                          onTap: () => Navigator.pop(context),
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
                  
                  // Delete Button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
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
                          onTap: () {
                            setState(() {
                              _costCenters.removeAt(index);
                              _expandedIndex = null;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cost Center deleted successfully')),
                            );
                          },
                          child: const Center(
                            child: Text(
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
      ),
    );
  }
}

class CostCenter {
  final String name;
  final double allocatedBudget;
  final bool isActive;

  CostCenter({
    required this.name,
    required this.allocatedBudget,
    required this.isActive,
  });
}