import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/company_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/color_generator.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({Key? key}) : super(key: key);

  @override
  _CompanyManagementScreenState createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  Company? _company; // Initialize as null
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCompany();
  }

  Future<void> _fetchCompany() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.getAllCompanies();
      
      if (response['success'] == true) {
        final companiesData = response['data'] as List<dynamic>;
        
        if (companiesData.isNotEmpty) {
          // Assuming we only handle one company for now
          final companyData = companiesData.first;
          setState(() {
            _company = Company.fromJson(companyData);
          });
        } else {
          setState(() {
            _company = null;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch company');
      }
    } catch (e) {
      print('Error fetching company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load company: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createCompany(Company company) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final response = await ApiService.createCompany(company.toJson());
      
      if (response['success'] == true) {
        final newCompanyData = response['data']['company'];
        setState(() {
          _company = Company.fromJson(newCompanyData);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Company created successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create company');
      }
    } catch (e) {
      print('Error creating company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create company: $e')),
      );
      rethrow;
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _updateCompany(Company company) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final response = await ApiService.updateCompany(company.id, company.toJson());
      
      if (response['success'] == true) {
        final updatedCompanyData = response['data']['company'];
        setState(() {
          _company = Company.fromJson(updatedCompanyData);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Company updated successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update company');
      }
    } catch (e) {
      print('Error updating company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update company: $e')),
      );
      rethrow;
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

 /* // Sample email domain for dropdowns or future use
  final List<String> _domains = [
    'company.com',
    'business.org',
    'enterprise.net',
    'corp.io'
  ];
*/
  
  String _generateShortName(String companyName) {
    if (companyName.isEmpty) return 'CO';
    // Get first letter of each word and capitalize
    final words = companyName.split(' ');
    final initials = words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.yellow[600],
          ),
        ),
      );
    }
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
                  'Company',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Create/Edit Button Section
          Padding(
            padding: EdgeInsets.all(20),
            child: _company == null 
                ? _buildCreateCompanyButton()
                : _buildEditDeleteButtons(),
          ),

          SizedBox(height: 8),
          
          // Available Section Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Company Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                /*Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _company == null ? '0' : '1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),*/
              ],
            ),
          ),

          SizedBox(height: 16),

          // Company Card or Empty State
          Expanded(
            child: _company == null 
                ? _buildEmptyState()
                : _buildCompanyCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCompanyButton() {
    return Container(
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
          onTap: _isSubmitting ? null : () {
            _showCreateCompanyDialog();
          },
          child: Center(
            child: _isSubmitting
                ? CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create Company',
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
    );
  }

  Widget _buildEditDeleteButtons() {
    return Row(
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
                onTap: _isSubmitting ? null : () {
                  _showEditCompanyDialog();
                },
                child: Center(
                  child: _isSubmitting
                      ? CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Edit Company',
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
        /*Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _isSubmitting ? Colors.grey : Colors.red,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (_isSubmitting ? Colors.grey : Colors.red).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isSubmitting ? null : () {
                _showDeleteConfirmation();
              },
              child: Center(
                child: _isSubmitting
                    ? CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Icon(Icons.delete, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        */
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Company Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your company profile to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard() {
    final shortName = _generateShortName(_company!.name);
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorGenerator.getRandomColor(_company!.name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorGenerator.getRandomColor(_company!.name).withOpacity(0.2), 
                width: 2
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Company Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: ColorGenerator.getRandomColor(_company!.name),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          shortName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Company Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _company!.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _company!.emailDomain,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(height: 20),
                
                // Details Grid
                Row(
                  children: [
                    _buildDetailItem(
                      icon: Icons.location_on,
                      title: 'Address',
                      value: _company!.address,
                    ),
                    SizedBox(width: 24),
                    _buildDetailItem(
                      icon: Icons.email,
                      title: 'Email Domain',
                      value: _company!.emailDomain,
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                Row(
                  children: [
                    _buildDetailItem(
                      icon: Icons.phone,
                      title: 'Contact No',
                      value: _company!.contactNumber,
                    ),
                    SizedBox(width: 24),
                    _buildDetailItem(
                      icon: Icons.circle,
                      title: 'Status',
                      value: _company!.isActive ? 'Active' : 'Inactive',
                      valueColor: _company!.isActive ? Colors.green : Colors.orange,
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      title: 'Created At',
                      value: _company!.createdAt?.toIso8601String().split('T').first ?? 'N/A',
                    ),
                    SizedBox(width: 24),
                    _buildDetailItem(
                      icon: Icons.update,
                      title: 'Updated At',
                      value: _company!.updatedAt?.toIso8601String().split('T').first ?? 'N/A',
                    )
                  ],
                )
              ],
            ),
          ),
        ),
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

  void _showCreateCompanyDialog() {
    String name = '';
    String address = '';
    String emailDomain = '';
    String contactNumber = '';
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
                      'New Company',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Company Name Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Company Name *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.business, color: Colors.yellow),
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
                      hintText: 'e.g., Reliable General Works',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 16),

                  // Address Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Address *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.yellow),
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
                      hintText: 'e.g., 123 Main Street, Colombo',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => address = value,
                  ),
                  const SizedBox(height: 16),

                  // Email Domain Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Email Domain *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.email, color: Colors.yellow),
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
                      hintText: 'e.g., company.com',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => emailDomain = value,
                  ),
                  const SizedBox(height: 16),

                  // Contact No Field
                  TextField(
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Contact No *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.phone, color: Colors.yellow),
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
                      hintText: 'e.g., +94 11 2345678',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => contactNumber = value,
                  ),
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active Company",
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
                      
                      // Create Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (_isSubmitting ? Colors.grey : Colors.yellow).withOpacity(0.3),
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
                                if (name.isNotEmpty && address.isNotEmpty && 
                                    emailDomain.isNotEmpty && contactNumber.isNotEmpty) {
                                  try {
                                    final newCompany = Company(
                                      id: 0, // Will be generated by backend
                                      name: name,
                                      address: address,
                                      emailDomain: emailDomain,
                                      contactNumber: contactNumber,
                                      isActive: isActive,
                                    );
                                    
                                    await _createCompany(newCompany);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    // Error handling is done in _createCompany
                                  }
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
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

  void _showEditCompanyDialog() {
    String name = _company!.name;
    String address = _company!.address;
    String emailDomain = _company!.emailDomain;
    String contactNumber = _company!.contactNumber;
    bool isActive = _company!.isActive;

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
                      'Edit Company',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Company Name Field
                  TextField(
                    controller: TextEditingController(text: name),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Company Name *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.business, color: Colors.yellow),
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

                  // Address Field
                  TextField(
                    controller: TextEditingController(text: address),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Address *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.yellow),
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
                    onChanged: (value) => address = value,
                  ),
                  const SizedBox(height: 16),

                  // Email Domain Field
                  TextField(
                    controller: TextEditingController(text: emailDomain),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Email Domain *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.email, color: Colors.yellow),
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
                    onChanged: (value) => emailDomain = value,
                  ),
                  const SizedBox(height: 16),

                  // Contact No Field
                  TextField(
                    controller: TextEditingController(text: contactNumber),
                    style: const TextStyle(color: Colors.yellow),
                    decoration: InputDecoration(
                      labelText: 'Contact No *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      floatingLabelStyle: const TextStyle(color: Colors.yellow),
                      prefixIcon: const Icon(Icons.phone, color: Colors.yellow),
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
                    onChanged: (value) => contactNumber = value,
                  ),
                  const SizedBox(height: 8),

                  // Active/Inactive Toggle
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active Company",
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
                      
                      // Save Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.yellow[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (_isSubmitting ? Colors.grey : Colors.yellow).withOpacity(0.3),
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
                                if (name.isNotEmpty && address.isNotEmpty && 
                                    emailDomain.isNotEmpty && contactNumber.isNotEmpty) {
                                  try {
                                    final newCompany = Company(
                                      id: _company!.id,
                                      name: name,
                                      address: address,
                                      emailDomain: emailDomain,
                                      contactNumber: contactNumber,
                                      isActive: isActive,
                                    );
                                    
                                    await _updateCompany(newCompany);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    // Error handling is done in _createCompany
                                  }
                                }
                              },
                              child: Center(
                                child: _isSubmitting
                                    ? CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
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

/* // Company deletion part
  Future<void> _deleteCompany() async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final response = await ApiService.deleteCompany(_company!.id);
      print('Delete response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _company = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Company deleted successfully')),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete company');
      }
    } catch (e) {
      print('Error deleting company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete company: $e')),
      );
      rethrow;
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showDeleteConfirmation() {
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
                  'Delete Company',
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
                'Are you sure you want to delete ${_company!.name} company?',
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
                  
                  // Delete Button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isSubmitting ? Colors.grey : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_isSubmitting ? Colors.grey : Colors.red).withOpacity(0.3),
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
                                    
                                    await _deleteCompany();
                                    Navigator.pop(context);
                                  } catch (e) {
                                    // Error handling is done in _createCompany
                                  }
                              
                              },
                              child: Center(
                                child: _isSubmitting
                                  ? CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
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
      ),
    );
  }
*/

}
