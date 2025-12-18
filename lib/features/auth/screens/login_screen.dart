import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/data/services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Please enter both username and password");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      
      _showSuccessDialog(res['message'] ?? "Login Successful!");
            
    } catch (e) {
      _showErrorDialog("Login failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

/*
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
*/

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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // User can't close by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
      ),
    );
    
    // Auto navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }
  */
  
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF56ab2f),
                Color(0xFFa8e063),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
              children: [
                // First Row - Icon centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 14), // Space between icon and text
                
                // Second Row - Text centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Login Successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ],
                ),
                
                //SizedBox(height: 12),
                
                /*Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),*/
                
                //SizedBox(height: 25),
                
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  'Redirecting in 2 seconds...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
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
        automaticallyImplyLeading: false, // This removes the back button
        title: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 20), // Padding around the title
          child: const Center(
            child: Text('Login', 
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 0, bottom: 10, left: 24, right: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              const SizedBox(height: 20),

              Image.asset('Icon.png', height: 240),

              const SizedBox(height: 20),

              // Username Field
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.yellow),
                decoration: InputDecoration(
                  labelText: 'User Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: const TextStyle(color: Colors.yellow),
                  prefixIcon: const Icon(Icons.person, color:Color.fromARGB(255, 247, 178, 30)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.yellow),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: const TextStyle(color: Colors.yellow),
                  prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 247, 178, 30)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color.fromARGB(211, 255, 235, 59),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _navigateToSignUp,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Login Button with Gradient
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Important: Set to transparent
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero, // Remove default padding for gradient
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Create account text
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    'New user ? ',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToSignUp,
                    child: const Text(
                      ' Create account',
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

              const SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
