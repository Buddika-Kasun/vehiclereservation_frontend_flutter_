import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vehiclereservation_frontend_flutter_/core/routes/app_routes.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/update_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/features/dashboard/screens/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/download_progress_dialog.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/update_dialog.dart';
import 'package:vehiclereservation_frontend_flutter_/shared/widgets/installation_progress_dialog.dart';

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
  final UpdateService _updateService = UpdateService();
  bool _updateChecked = false;
  bool _checkingUpdate = false;

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

    // Start checking for updates after animation begins
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdate || _updateChecked) return;

    _checkingUpdate = true;

    try {
      // Add a small delay to ensure animation is visible
      await Future.delayed(const Duration(milliseconds: 500));

      final updateResponse = await _updateService.checkForUpdate();

      if (mounted) {
        if (updateResponse.updateAvailable) {
          _handleUpdate(updateResponse);
        } else {
          _proceedToApp();
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
      if (mounted) {
        _proceedToApp();
      }
    } finally {
      _checkingUpdate = false;
    }
  }

  void _handleUpdate(UpdateCheckResponse response) {
    if (!mounted) return;

    if (response.updateType == 'silent' && response.data?.downloadUrl != null) {
      _performSilentUpdate(response.data!);
    } else if (response.updateType == 'store_redirect') {
      _redirectToStore(response.data);
    } else if (response.updateType == 'user_confirmation') {
      _showUpdateDialog(response.data!);
    } else {
      _proceedToApp();
    }
  }

  void _performSilentUpdate(AppUpdate update) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        fileName: update.originalFileName ?? 'update_v${update.version}.apk',
        fileSize: update.fileSize,
        downloadTask: (onProgress) async {
          try {
            await _updateService.downloadAndInstallUpdate(
              downloadUrl: update.downloadUrl!,
              fileName:
                  update.originalFileName ?? 'update_v${update.version}.apk',
              context: context, // Pass context here
              onDownloadProgress: onProgress,
              onDownloadComplete: (message) {
                // Close download dialog
                Navigator.of(context).pop();

                // Show installation dialog
                _showInstallationDialog(update);
              },
              onInstallStart: (message) {
                // Update installation dialog
                _updateInstallationDialog(message);
              },
              onInstallComplete: (message) {
                // Show final message and proceed
                _showInstallationCompleteDialog(update, message);
              },
              onError: (error) {
                Navigator.of(context).pop();
                _showErrorDialog('Update failed: $error');
              },
            );
          } catch (e) {
            Navigator.of(context).pop();
            _showErrorDialog('Update error: $e');
          }
        },
      ),
    );
  }

  void _showInstallationDialog(AppUpdate update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InstallationProgressDialog(
        update: update,
        onCancel: () {
          Navigator.of(context).pop();
          _proceedToApp();
        },
      ),
    );
  }

  void _updateInstallationDialog(String message) {
    // Find and update the installation dialog
    final context = this.context;
    if (context != null && mounted) {
      final dialogContext = context
          .findAncestorStateOfType<State<InstallationProgressDialog>>();
      if (dialogContext != null && dialogContext.mounted) {
        // Update the dialog state if needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showInstallationCompleteDialog(AppUpdate update, String message) {
    // Close any open dialogs
    Navigator.of(context).popUntil((route) => route.isFirst);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Installation Started'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Update ${update.version}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
              'The system installer will now open. Please follow the on-screen instructions to complete the installation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // The app will close when installer opens
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  _proceedToApp();
                }
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToApp();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _redirectToStore(AppUpdate? update) {
    // For web, we can't redirect to app stores
    // For mobile apps, you would implement store redirection here

    // Show a message for web
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (update != null)
                Text(
                  'Version ${update.version} is available on the app store.',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 16),
              const Text(
                'Please visit the app store to download the latest version.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToApp();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showUpdateDialog(AppUpdate update) {
    showDialog(
      context: context,
      barrierDismissible: !update.isMandatory,
      builder: (context) => UpdateDialog(
        update: update,
        isMandatory: update.isMandatory,
        onUpdate: () {
          Navigator.of(context).pop();
          _performSilentUpdate(update);
        },
        onLater: update.isMandatory
            ? null
            : () {
                Navigator.of(context).pop();
                _proceedToApp();
              },
      ),
    );
  }

  void _proceedToApp() {
    if (_updateChecked) return;
    _updateChecked = true;

    Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      bool hasSession = await StorageService.hasValidSession;
      if (hasSession) {
        final user = StorageService.userData;
        final token = await SecureStorageService().accessToken;
        if (user != null && token != null) {
          /*
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          */

          // Use route navigation instead of MaterialPageRoute
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          
          return;
        }
      }

      /*
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      */
      // Use route navigation
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      
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

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.1),

                // Logo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: isSmallScreen
                          ? size.width * 0.6
                          : size.width * 0.4,
                      height: isSmallScreen
                          ? size.width * 0.7
                          : size.width * 0.4,
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
                          Container(
                            width: isSmallScreen
                                ? size.width * 0.5
                                : size.width * 0.3,
                            height: isSmallScreen
                                ? size.width * 0.5
                                : size.width * 0.3,
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
                            padding: EdgeInsets.all(isSmallScreen ? 30 : 40),
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

                // App name
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

                Expanded(child: Container()),

                // Loading progress
                Container(
                  margin: EdgeInsets.only(
                    bottom: size.height * 0.18,
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
                            _checkingUpdate
                                ? "Checking for updates..."
                                : "Initializing ${(_progressAnimation.value * 100).toInt()}%",
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

            // Footer
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

      final offsetX = 10 * sin(animationValue * 2 * pi + i);
      final offsetY = 10 * cos(animationValue * 2 * pi + i);

      paint.color = Colors.yellow.withOpacity(0.1 + rng.nextDouble() * 0.1);
      canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius, paint);

      paint.color = Colors.yellow.withOpacity(0.05);
      canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
