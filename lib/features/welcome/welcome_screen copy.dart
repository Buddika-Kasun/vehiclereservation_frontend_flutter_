// lib/features/welcome/welcome_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    Timer(const Duration(seconds: 3), () async {
      bool hasSession = await StorageService.hasValidSession;
      if (hasSession) {
        final user = StorageService.userData;
        final token = await SecureStorageService().accessToken;
        if (user != null && token != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }
      }
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, const Color(0xFF111111), Colors.black],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlePainter(_controller.value),
                  );
                },
              ),
            ),

            // Main content - Single Column to avoid overlap
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top spacer
                SizedBox(height: size.height * 0.1),

                // Large visible logo - INCREASED SIZE
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: isSmallScreen
                          ? size.width *
                                0.6 // Increased from 0.5
                          : size.width * 0.4, // Increased from 0.3
                      height: isSmallScreen
                          ? size.width *
                                0.7 // Increased from 0.5
                          : size.width * 0.4, // Increased from 0.3
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow[600]!.withOpacity(0.4),
                            blurRadius: 50,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.yellow[400]!.withOpacity(0.2),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.yellow[800]!.withOpacity(0.6),
                                  Colors.yellow[600]!.withOpacity(0.4),
                                  Colors.orange[400]!.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.2, 0.4, 0.8],
                              ),
                            ),
                          ),

                          // Logo container - INCREASED SIZE
                          Container(
                            width: isSmallScreen
                                ? size.width *
                                      0.5 // Increased from 0.4
                                : size.width * 0.3, // Increased from 0.25
                            height: isSmallScreen
                                ? size.width *
                                      0.5 // Increased from 0.4
                                : size.width * 0.3, // Increased from 0.25
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.yellow[400]!.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            padding: EdgeInsets.all(
                              isSmallScreen ? 30 : 40,
                            ), // Increased padding
                            child: Image.asset(
                              "assets/images/logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // App name - CLEAR AND VISIBLE
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                    child: Column(
                      children: [
                        Text(
                          "WELCOME TO",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // PCW RIDE with strong yellow gradient
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [
                                Colors.yellow[800]!,
                                Colors.yellow[600]!,
                                Colors.yellow[400]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            "PCW RIDE",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 32 : 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "Vehicle Reservation System",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Spacer to push progress bar down
                Expanded(child: Container()),

                // Loading progress - FIXED POSITION
                Container(
                  margin: EdgeInsets.only(
                    bottom: size.height * 0.18, // Space for footer
                    left: size.width * 0.15,
                    right: size.width * 0.15,
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.yellow[600]!,
                              ),
                              backgroundColor: Colors.grey[900]!.withOpacity(
                                0.5,
                              ),
                              minHeight: 8,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            "Initializing ${(_progressAnimation.value * 100).toInt()}%",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer - FIXED AT BOTTOM
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: size.width * 0.4,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey[800]!,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /*
                        Icon(
                          Icons.code_rounded,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        */
                        const SizedBox(width: 8),
                        Text(
                          'Developed by ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.blueAccent,
                                Colors.lightBlueAccent,
                                Colors.blue[700]!,
                                Colors.cyanAccent,
                              ],
                              stops: const [0.0, 0.3, 0.6, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Text(
                            'Axperia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double animationValue;

  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = Random(42);

    for (int i = 0; i < 20; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 3 + 1;

      // Animate particle movement
      final offsetX = 10 * sin(animationValue * 2 * pi + i);
      final offsetY = 10 * cos(animationValue * 2 * pi + i);

      // Draw particle with yellow color
      paint.color = Colors.yellow.withOpacity(0.1 + rng.nextDouble() * 0.1);
      canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius, paint);

      // Draw glow
      paint.color = Colors.yellow.withOpacity(0.05);
      canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
