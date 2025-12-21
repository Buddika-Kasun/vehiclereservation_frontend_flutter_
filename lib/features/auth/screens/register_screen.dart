import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/department_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isAppActive = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasCompanyEmail = true;
  String? _selectedRole;
  String? _selectedDepartment;

  List<Department> _departments = [];

  final List<String> _roles = ['Employee', 'Admin', 'HR', 'Security', 'Driver', 'Supervisor'];

  Future<void> _register() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (displayName.isEmpty ||
        username.isEmpty ||
        mobile.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        (_hasCompanyEmail && email.isEmpty)) {
      _showErrorDialog('Please fill all required fields');
      return;
    }

    if (!RegExp(r"^[0-9]{10}$").hasMatch(mobile)) {
      _showErrorDialog('Please enter a valid 10-digit mobile number');
      return;
    }

    if (_hasCompanyEmail &&
        !RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password should be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    if (_selectedRole == null) {
      _showErrorDialog('Please select a user role');
      return;
    }

    if (_selectedDepartment == null) {
      _showErrorDialog('Please select a department');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.signUp(
        username,
        password,
        confirmPassword,
        _hasCompanyEmail ? email : null,
        phone: mobile,
        displayName: displayName,
        role: _selectedRole,
        departmentId: _selectedDepartment,
      );

      _showSuccessDialog(res['message'] ?? 'Registration successful');
    } catch (e) {
      _showErrorDialog('Registration failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFff7e5f), // Orange-red
                Color(0xFFfeb47b), // Light orange
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Color(0xFFff7e5f),
                ),
              ),

              SizedBox(height: 12),

              // Title
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 4),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 16),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFFff7e5f),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320, // Fixed width
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  'Registration Successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF56ab2f),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkAppStatus();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await ApiService.getDepartmentsForReg();

      if (response['success'] == true) {
        final List<dynamic> departments = response['data']['departments'] ?? [];
        setState(() {
          _departments = departments
              .map((data) => Department.fromJson(data))
              .toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load cost centers');
      }
    } catch (e) {
      print('Error loading cost centers: $e');
      rethrow;
    }
  }

  Future<void> _checkAppStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.getRegisterStatus();

      if (response['success'] == true) {
        setState(() {
          _isAppActive = response['data'] ?? false;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to get app status');
      }
    } catch (e) {
      print('Error checking app status: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking app status...'),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.pop(context);
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Failed to check app status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(onPressed: _checkAppStatus, child: Text('Retry')),
          SizedBox(height: 16),
          TextButton(onPressed: _goToLogin, child: Text('Go to Login')),
        ],
      ),
    );
  }

  Widget _buildAppInactiveWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 80, color: Colors.orange),
          SizedBox(height: 24),
          Text(
            'App is Not Active',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Please contact system administrator to activate the application',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _goToLogin,
            icon: Icon(Icons.login),
            label: Text('Go to Login Page'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          SizedBox(height: 16),
          TextButton(onPressed: _checkAppStatus, child: Text('Check Again')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: const Center(
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _hasError
          ? _buildErrorWidget()
          : _isAppActive
          ? _buildSignUpForm()
          : _buildAppInactiveWidget(),
    );
  }

  Widget _buildSignUpForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0, bottom: 0, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Switch for company email
            Container(
              padding: const EdgeInsets.only(
                top: 0,
                bottom: 20,
                left: 4,
                right: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "I don't have a company email",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: !_hasCompanyEmail,
                      onChanged: (bool value) {
                        setState(() {
                          _hasCompanyEmail = !value;
                          print(_hasCompanyEmail);
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

            // Display Name Field
            TextField(
              controller: _displayNameController,
              style: const TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                labelText: 'Display Name *',
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Username Field
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                labelText: 'Username *',
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.account_circle,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Mobile Number Field
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                labelText: 'Mobile Number *',
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.phone_android,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
            ),

            // Company Email Field (conditionally shown)
            if (_hasCompanyEmail) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.yellow),
                decoration: InputDecoration(
                  labelText: 'Company Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: const TextStyle(color: Colors.yellow),
                  prefixIcon: const Icon(
                    Icons.email,
                    color: Color.fromARGB(255, 247, 178, 30),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade600,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.yellow,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.black,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                labelText: 'Password *',
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Color.fromARGB(211, 255, 235, 59),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Color.fromARGB(211, 255, 235, 59),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // User Role Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'User Role *',
                labelStyle: TextStyle(
                  color: _selectedRole != null
                      ? Colors.yellow[600]
                      : Colors.grey[500],
                ),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.admin_panel_settings,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
              dropdownColor: Colors.black,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color.fromARGB(211, 255, 235, 59),
              ),
              style: const TextStyle(color: Colors.yellow),
              items: _roles.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.yellow),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Department Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Department',
                labelStyle: TextStyle(
                  color: _selectedDepartment != null
                      ? Colors.yellow[600]
                      : Colors.grey[500],
                ),
                floatingLabelStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(
                  Icons.admin_panel_settings,
                  color: Color.fromARGB(255, 247, 178, 30),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
                filled: true,
                fillColor: Colors.black,
              ),
              dropdownColor: Colors.black,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color.fromARGB(211, 255, 235, 59),
              ),
              style: const TextStyle(color: Colors.yellow),
              items: _departments.map((department) {
                return DropdownMenuItem(
                  value: department.id.toString(),
                  child: Text(
                    department.name,
                    style: const TextStyle(color: Colors.yellow),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),

            const SizedBox(height: 30),

            // Create Account Button with Gradient
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFf7971e), // Orange
                        Color(0xFFffd200), // Yellow
                      ],
                      stops: [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Text(
                            'Create account',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  'Already have an account ? ',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    ' Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset('assets/images/Icon_half.png'),
            ),
          ],
        ),
      ),
    );
  }
}

