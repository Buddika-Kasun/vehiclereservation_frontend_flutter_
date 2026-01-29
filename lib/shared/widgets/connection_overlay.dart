// lib/core/widgets/connection_overlay.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/connectivity_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/server_health_service.dart';

class ConnectionOverlay extends StatefulWidget {
  final Widget child;

  const ConnectionOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectionOverlay> createState() => _ConnectionOverlayState();
}

class _ConnectionOverlayState extends State<ConnectionOverlay> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final ServerHealthService _serverHealthService = ServerHealthService();

  bool _showOverlay = false;
  String _statusMessage = '';
  Color _overlayColor = Colors.red;
  IconData _overlayIcon = Icons.wifi_off;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners();
    });
  }

  void _setupListeners() {
    if (_initialized) return;

    _initialized = true;

    _serverHealthService.serverCheckingNotifier.addListener(_updateStatus);

    // Listen to connectivity changes
    _connectivityService.connectionNotifier.addListener(_onConnectivityChanged);

    // Listen to server health changes
    _serverHealthService.serverHealthNotifier.addListener(
      _onServerHealthChanged,
    );

    // Initial check
    _updateStatus();
  }

  void _onConnectivityChanged() {
    _updateStatus();

    if (_connectivityService.isConnected) {
      _serverHealthService.checkServerHealth();
    }
  }

  void _onServerHealthChanged() {
    _updateStatus();
  }

  void _checkServerOnReconnect() {
    // Just show checking message and let the ServerHealthService handle the actual check
    if (mounted) {
      setState(() {
        _showOverlay = true;
        _statusMessage = 'Checking server connection...';
        _overlayColor = Colors.blue.withOpacity(0.9);
        _overlayIcon = Icons.refresh;
      });
    }

    // The ServerHealthService will automatically check when connectivity changes
    // via its _onConnectivityChanged listener
  }

  void _updateStatus() {
    if (!mounted) return;

    final isChecking = _serverHealthService.serverCheckingNotifier.value;
    final hasInitialCheck = _serverHealthService.hasCompletedInitialCheck;

    final isConnected = _connectivityService.isConnected;
    final isHealthy = _serverHealthService.isServerHealthy;

    setState(() {
      
      if (!isConnected) {
        _showOverlay = true;
        _statusMessage =
            'No Internet Connection\nPlease check your network settings';
        _overlayColor = Colors.red.withOpacity(0.9);
        _overlayIcon = Icons.wifi_off;
        return;
      }

      if (isChecking && hasInitialCheck) {
        _showOverlay = true;
        _statusMessage = 'Checking server connection...';
        _overlayColor = Colors.blue.withOpacity(0.9);
        _overlayIcon = Icons.refresh;
        return;
      }

      if (!isHealthy) {
        _showOverlay = true;
        _statusMessage = 'Server Under Maintenance\nPlease try again later';
        _overlayColor = Colors.orange.withOpacity(0.9);
        _overlayIcon = Icons.cloud_off;
        return;
      }

      _showOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isServerHealthy = _serverHealthService.isServerHealthy;

    return Stack(
      children: [
        widget.child,

        if (_showOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  constraints: BoxConstraints(maxWidth: 400, minHeight: 250),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_overlayColor, _overlayColor.withOpacity(0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon or loading indicator
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child:
                            _overlayIcon == Icons.refresh
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(_overlayIcon, size: 40, color: Colors.white),
                                            ),

                      SizedBox(height: 20),

                      // Status message
                      Container(
                        constraints: BoxConstraints(maxHeight: 80),
                        child: SingleChildScrollView(
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Connection details - Only for offline
                      if (_overlayIcon == Icons.wifi_off)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Make sure Wi-Fi or mobile data is turned on',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),

                      // Retry button - Only for server issues when online
                      if (_overlayIcon == Icons.cloud_off &&
                          isServerHealthy == false)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: ElevatedButton(
                            onPressed: () {
                              // Reset checking state and let ServerHealthService handle it
                              if (mounted) {
                                setState(() {
                                  _statusMessage =
                                      'Checking server connection...';
                                  _overlayColor = Colors.blue.withOpacity(0.9);
                                  _overlayIcon = Icons.refresh;
                                });
                              }
                              _serverHealthService.checkServerHealth();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'RETRY CONNECTION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _serverHealthService.serverCheckingNotifier.removeListener(_updateStatus);

    _connectivityService.connectionNotifier.removeListener(
      _onConnectivityChanged,
    );
    _serverHealthService.serverHealthNotifier.removeListener(
      _onServerHealthChanged,
    );
    super.dispose();
  }
}
