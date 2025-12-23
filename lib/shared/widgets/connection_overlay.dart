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
  bool _isCheckingServer = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to connectivity changes
    _connectivityService.connectionNotifier.addListener(_onConnectivityChanged);
    _connectivityService.connectionStatusNotifier.addListener(
      _onConnectivityChanged,
    );

    // Listen to server health changes
    _serverHealthService.serverHealthNotifier.addListener(
      _onServerHealthChanged,
    );
    _serverHealthService.serverStatusNotifier.addListener(
      _onServerHealthChanged,
    );

    // Initial check
    _updateStatus();
  }

  void _onConnectivityChanged() {
    final isConnected = _connectivityService.isConnected;

    if (!isConnected) {
      _wasOffline = true;
      _updateStatus(); // Show offline immediately
    } else if (isConnected && _wasOffline) {
      // Just came back online
      _wasOffline = false;
      _checkServerOnReconnect();
    }
  }

  void _onServerHealthChanged() {
    if (_connectivityService.isConnected) {
      // Only update if we're online
      _updateStatus();
    }
  }

  Future<void> _checkServerOnReconnect() async {
    // Show checking message immediately
    if (mounted) {
      setState(() {
        _isCheckingServer = true;
        _showOverlay = true;
        _statusMessage = 'Checking server connection...';
        _overlayColor = Colors.blue.withOpacity(0.9);
        _overlayIcon = Icons.refresh;
      });
    }

    try {
      // Wait a moment for network to stabilize
      await Future.delayed(Duration(milliseconds: 100));

      // Check server health
      await _serverHealthService.checkServerHealth();
    } catch (e) {
      // Ignore errors, status will update via listener
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingServer = false;
        });
      }
    }
  }

  void _updateStatus() {
    if (!mounted) return;

    final isConnected = _connectivityService.isConnected;
    final isServerHealthy = _serverHealthService.isServerHealthy;

    setState(() {
      if (!isConnected) {
        _showOverlay = true;
        _statusMessage =
            'No Internet Connection\nPlease check your network settings';
        _overlayColor = Colors.red.withOpacity(0.9);
        _overlayIcon = Icons.wifi_off;
      } else if (_isCheckingServer) {
        // Keep showing checking message
        _showOverlay = true;
        _statusMessage = 'Checking server connection...';
        _overlayColor = Colors.blue.withOpacity(0.9);
        _overlayIcon = Icons.refresh;
      } else if (isServerHealthy != null && !isServerHealthy!) {
        // Explicitly check for false (not null)
        _showOverlay = true;
        _statusMessage = 'Server Under Maintenance\nPlease try again later';
        _overlayColor = Colors.orange.withOpacity(0.9);
        _overlayIcon = Icons.cloud_off;
      } else {
        // Server is healthy OR status is unknown but we're connected
        _showOverlay = false;
      }
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
                            _isCheckingServer || _overlayIcon == Icons.refresh
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
                          isServerHealthy != null &&
                          !isServerHealthy!)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: ElevatedButton(
                            onPressed: () {
                              _checkServerOnReconnect();
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
    _connectivityService.connectionNotifier.removeListener(
      _onConnectivityChanged,
    );
    _connectivityService.connectionStatusNotifier.removeListener(
      _onConnectivityChanged,
    );
    _serverHealthService.serverHealthNotifier.removeListener(
      _onServerHealthChanged,
    );
    _serverHealthService.serverStatusNotifier.removeListener(
      _onServerHealthChanged,
    );
    super.dispose();
  }
}
