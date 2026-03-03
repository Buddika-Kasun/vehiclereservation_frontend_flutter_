import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:vehiclereservation_frontend_flutter_/core/routes/app_routes.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/firebase_notification_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/pending_navigation_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/navigation_helper.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';

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

    // Start checking for Play Store updates
    _checkForPlayStoreUpdates();
    //_checkForPlayStoreUpdatesMock();
  }

  Future<void> _checkForPlayStoreUpdatesMock() async {
    if (_checkingUpdate || _updateChecked) return;

    _checkingUpdate = true;

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // 🔥 TEST MODE - Change these values to test different flows
      final mockUpdate = {
        'updateAvailable': true, // true = update exists, false = no update
        'updatePriority': 2, // 0 = silent, 1 = flexible, 2+ = immediate
      };

      print(
        '📱 TEST MODE: Update available: ${mockUpdate['updateAvailable']}, Priority: ${mockUpdate['updatePriority']}',
      );

      if (!mounted) return;

      if (mockUpdate['updateAvailable'] == true) {
        final priority = mockUpdate['updatePriority'] as int;

        if (priority >= 2) {
          // Immediate update
          _startImmediateUpdate();
        } else if (priority == 1) {
          // Flexible update
          _showFlexibleUpdateDialog();
        } else {
          // Silent update (priority 0)
          _startSilentUpdate();
        }
      } else {
        // No update
        _proceedToApp();
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) _proceedToApp();
    } finally {
      _checkingUpdate = false;
    }
  }

  Future<void> _checkForPlayStoreUpdates() async {
    if (_checkingUpdate || _updateChecked) return;

    _checkingUpdate = true;

    try {
      // Add small delay to show animation
      await Future.delayed(const Duration(milliseconds: 800));

      // Check for update
      final updateInfo = await InAppUpdate.checkForUpdate();

      print('📱 Update availability: ${updateInfo.updateAvailability}');
      print('📱 Update version: ${updateInfo.availableVersionCode}');
      print('📱 Update priority: ${updateInfo.updatePriority}');
      print('📱 Is update allowed: ${updateInfo.immediateUpdateAllowed}');

      if (!mounted) return;

      // Handle based on update availability
      switch (updateInfo.updateAvailability) {
        case UpdateAvailability.updateAvailable:
          // Update is available
          _handleUpdateAvailable(updateInfo);
          break;

        case UpdateAvailability.developerTriggeredUpdateInProgress:
          // An update is already in progress
          _showResumeUpdateDialog();
          break;

        case UpdateAvailability.updateNotAvailable:
        default:
          // No update available
          _proceedToApp();
          break;
      }
    } catch (e) {
      print('Error checking Play Store updates: $e');
      // Check if it's because not on Play Store (debug build)
      if (mounted) {
        _proceedToApp();
      }
    } finally {
      _checkingUpdate = false;
    }
  }

  /// Handle different update priorities
  void _handleUpdateAvailable(AppUpdateInfo updateInfo) {
    if (!mounted) return;

    final priority = updateInfo.updatePriority ?? 0;
    //final priority = 1;

    if (priority >= 2) {
      // Immediate update (must update now)
      _startImmediateUpdate();
    } else if (priority == 1) {
      // Flexible update (user can postpone)
      _showFlexibleUpdateDialog();
    } else {
      // Silent update (priority 0) - auto update in background
      _startSilentUpdate();
    }
  }

  /// SILENT UPDATE - Auto download without user interaction
  void _startSilentUpdate() {
    if (!mounted) return;

    print('📱 Starting silent update...');

    // Show subtle notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading update in background...'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    // Start silent update
    InAppUpdate.startFlexibleUpdate()
        .then((_) {
          print('📱 Silent update started successfully');

          // Complete the update after download
          _completeUpdate();
        })
        .catchError((error) {
          print('❌ Silent update failed: $error');

          // Fallback to flexible update
          if (mounted) {
            _showFlexibleUpdateDialog();
          }
        });
  }

  /// FLEXIBLE UPDATE - User can postpone
  void _showFlexibleUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text('Update Available'),
          ],
        ),
        content: const Text(
          'A new version is available. Would you like to update now?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToApp(); // User postpones update
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startFlexibleUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Start flexible update
  Future<void> _startFlexibleUpdate() async {
    if (!mounted) return;

    try {
      print('📱 Starting flexible update...');

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );

      // Start flexible update
      await InAppUpdate.startFlexibleUpdate();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Complete the update
      _completeUpdate();
    } catch (e) {
      print('❌ Flexible update error: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Update failed: $e');
      }
    }
  }

  /// IMMEDIATE UPDATE - Force update
  void _startImmediateUpdate() {
    if (!mounted) return;

    print('📱 Starting immediate update...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Update Required'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, size: 60, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'A critical update is required to continue using the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performImmediateUpdate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  /// Perform immediate update
  Future<void> _performImmediateUpdate() async {
    if (!mounted) return;

    try {
      print('📱 Performing immediate update...');

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      // Start immediate update
      await InAppUpdate.performImmediateUpdate();

      // Note: App will restart automatically for immediate updates
      // This code may not execute
    } catch (e) {
      print('❌ Immediate update error: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Update failed: $e');
      }
    }
  }

  /// Complete flexible/silent update
  Future<void> _completeUpdate() async {
    if (!mounted) return;

    try {
      print('📱 Completing update...');

      // Ask user to restart
      _showRestartDialog();
    } catch (e) {
      print('❌ Complete update error: $e');
      if (mounted) {
        _showErrorDialog('Failed to complete update: $e');
      }
    }
  }

  /// Show resume update dialog (if update was interrupted)
  void _showResumeUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update in Progress'),
        content: const Text(
          'An update was already in progress. Resume it now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToApp();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              InAppUpdate.completeFlexibleUpdate();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  /// Show restart dialog
  void _showRestartDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Downloaded'),
        content: const Text(
          'The update has been downloaded. Restart the app to apply changes?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToApp(); // Continue using old version
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              InAppUpdate.completeFlexibleUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart Now'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToApp();
            },
            child: const Text('Continue'),
          ),
        ],
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

          // Send FCM token to backend
          //await FirebaseNotificationService().sendTokenToBackend();

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handlePendingNotification();
          });

          return;
        }
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    });
  }

  void _handlePendingNotification() {
    final pendingData = PendingNavigationService().getPendingNotification();
    if (pendingData != null && !PendingNavigationService().isNavigating) {
      print("📱 Handling pending notification from welcome screen");
      PendingNavigationService().isNavigating = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToNotificationScreen(pendingData);
        PendingNavigationService().clearPendingNotification();
      });
    }
  }

  void _navigateToNotificationScreen(Map<String, dynamic> data) {
    final type = data['type']?.toString().toUpperCase() ?? 'GENERAL';
    final id = data['id']?.toString();
    final tripId = int.tryParse(data['tripId']?.toString() ?? id ?? '0') ?? 0;

    switch (type) {
      case 'USER_REGISTERED':
        NavigationHelper.toUserCreations('pending');
        break;
      case 'USER_APPROVED':
        NavigationHelper.toUserCreations('approved');
        break;
      case 'USER_REJECTED':
        NavigationHelper.toUserCreations('rejected');
        break;
      case 'TRIP_CREATED':
      case 'TRIP_CANCELLED':
      case 'TRIP_CANCELLED_REQUESTER':
      case 'TRIP_APPROVED':
      case 'TRIP_REJECTED':
      case 'TRIP_READING_START_FOR_PASSENGER':
      case 'TRIP_STARTED_FOR_PASSENGER':
      case 'TRIP_FINISHED_FOR_REQUESTER':
      case 'TRIP_COMPLETED_FOR_REQUESTER':
        NavigationHelper.toMyRideTripDetails(tripId);
        break;
      case 'TRIP_CREATED_AS_DRAFT':
      case 'TRIP_CONFIRMED':
      case 'TRIP_CANCELLED_SUPERVISOR':
      case 'TRIP_STARTED_FOR_SUPERVISOR':
      case 'TRIP_FINISHED_FOR_SUPERVISOR':
      case 'TRIP_COMPLETED_FOR_SUPERVISOR':
        NavigationHelper.toReviewTripDetails(tripId);
        break;
      case 'TRIP_CONFIRMED_FOR_APPROVAL':
      case 'TRIP_APPROVED_BY_APPROVER':
      case 'TRIP_REJECTED_BY_APPROVER':
        NavigationHelper.toApprovalTripDetails(tripId);
        break;
      case 'TRIP_APPROVED_FOR_DRIVER':
      case 'TRIP_READING_START_FOR_DRIVER':
      case 'TRIP_STARTED':
      case 'TRIP_FINISHED':
      case 'TRIP_COMPLETED_FOR_DRIVER':
        NavigationHelper.toAssignRideTripDetails(tripId);
        break;
      case 'TRIP_APPROVED_FOR_SECURITY':
      case 'TRIP_READING_START':
      case 'TRIP_STARTED_FOR_SECURITY':
      case 'TRIP_COMPLETED':
        NavigationHelper.toMeterReading();
        break;
      default:
        NavigationHelper.toNotifications();
    }
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

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.1),

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
                            color: Colors.yellow.withValues(alpha: 0.4),
                            blurRadius: 50,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.2),
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
                                  Colors.yellow.shade800.withValues(alpha: 0.6),
                                  Colors.yellow.shade600.withValues(alpha: 0.4),
                                  Colors.orange.shade400.withValues(alpha: 0.2),
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
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.yellow.shade400.withValues(
                                  alpha: 0.3,
                                ),
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
                                Colors.yellow.shade800,
                                Colors.yellow.shade600,
                                Colors.yellow.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withValues(alpha: 0.5),
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
                                  color: Colors.black.withValues(alpha: 0.3),
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
                                Colors.yellow.shade600,
                              ),
                              backgroundColor: Colors.grey[900]!.withValues(
                                alpha: 0.5,
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
                          child: const Text(
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

      paint.color = Colors.yellow.withValues(
        alpha: 0.1 + rng.nextDouble() * 0.1,
      );
      canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius, paint);

      paint.color = Colors.yellow.withValues(alpha: 0.05);
      canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
