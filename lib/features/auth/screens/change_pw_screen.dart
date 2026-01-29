import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String username;
  final String mobile;
  final String? token;

  const ChangePasswordScreen({
    super.key,
    required this.username,
    required this.mobile,
    this.token,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Please enter both password fields');
      return;
    }

    if (newPassword.length < 6) {
      _showErrorDialog('Password should be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.resetPassword(
        username: widget.username,
        mobile: widget.mobile,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        token: widget.token,
      );

      if (res['success'] == true) {
        _showSuccessDialog(res['message'] ?? 'Password reset successful');
      } else {
        _showErrorDialog(res['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
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
              colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
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
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
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
          width: 320,
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
                Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      ); // Go to login
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
                      'GO TO LOGIN',
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

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              'Set New Password',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // This expands to take available space
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // User Info Display
                              Container(
                                padding: const EdgeInsets.only(bottom: 24, top:20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          color: Colors.yellow,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.username,
                                            style: TextStyle(
                                              color: Colors.yellow,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          color: Colors.yellow,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          widget.mobile,
                                          style: TextStyle(
                                            color: Colors.yellow,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Instruction Text
                              Container(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Text(
                                  'Create a new password for your account',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // New Password Field
                              TextField(
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                obscuringCharacter: '●',
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    206,
                                    59,
                                  ),
                                  fontSize: 16,
                                  letterSpacing: _obscureNewPassword
                                      ? 4.0
                                      : 1.0,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'New Password *',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: Colors.yellow,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Color.fromARGB(255, 247, 178, 30),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color.fromARGB(
                                        211,
                                        255,
                                        235,
                                        59,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureNewPassword =
                                            !_obscureNewPassword;
                                      });
                                    },
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
                              const SizedBox(height: 24),

                              // Confirm Password Field
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                obscuringCharacter: '●',
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    206,
                                    59,
                                  ),
                                  fontSize: 16,
                                  letterSpacing: _obscureConfirmPassword
                                      ? 4.0
                                      : 1.0,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password *',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: Colors.yellow,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color.fromARGB(255, 247, 178, 30),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color.fromARGB(
                                        211,
                                        255,
                                        235,
                                        59,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
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

                              const SizedBox(height: 50),

                              // Reset Password Button with Gradient
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _resetPassword,
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
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.black),
                                              ),
                                            )
                                          : const Text(
                                              'Reset Password',
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

                              // Back Link
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _goBack,
                                    child: const Text(
                                      'Back to Verification',
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
                            ],
                          ),
                        ),
                      ),

                      // Bottom Image (always at bottom)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0, top: 20),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Image.asset('assets/images/Icon_half.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
