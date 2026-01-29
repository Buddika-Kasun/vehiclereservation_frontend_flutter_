// lib/core/services/server_health_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/connectivity_service.dart';

class ServerHealthService {
  static final ServerHealthService _instance = ServerHealthService._internal();
  factory ServerHealthService() => _instance;
  ServerHealthService._internal();

  final Dio _dio = Dio();
  final ConnectivityService _connectivityService = ConnectivityService();
  Timer? _healthCheckTimer;

  bool _isServerHealthy = true; // Start as true
  bool get isServerHealthy => _isServerHealthy;

  final ValueNotifier<bool> serverHealthNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> serverStatusNotifier = ValueNotifier<String>(
    'Server Online',
  );
  final ValueNotifier<bool> serverCheckingNotifier = ValueNotifier<bool>(false);

  bool _isChecking = false; // Add flag to prevent duplicate checks
  bool _hasCompletedInitialCheck = false;
  bool get hasCompletedInitialCheck => _hasCompletedInitialCheck;

  void _updateStatus(bool isHealthy, String status) {
    
    // Only update if status changed to prevent unnecessary notifications
    if (_isServerHealthy != isHealthy || serverStatusNotifier.value != status) {
      _isServerHealthy = isHealthy;
      serverHealthNotifier.value = isHealthy;
      serverStatusNotifier.value = status;
      debugPrint('Server status updated: $status (Healthy: $isHealthy)');
    }
  }

  void startHealthMonitoring({int intervalSeconds = 30}) {
    // Listen to connectivity changes
    _connectivityService.connectionNotifier.addListener(_onConnectivityChanged);

    // Set initial status
    if (_connectivityService.isConnected) {
      checkServerHealth();
    } else {
      _updateStatus(true, 'Offline - Connection Required');
    }

    // Set up periodic checks
    _healthCheckTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
      timer,
    ) async {
      if (_connectivityService.isConnected) {
        await checkServerHealth(silent: true);
      }
    });
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isConnected) {
      debugPrint('Connectivity changed: Online, checking server...');
      checkServerHealth(); // This will trigger notifier when done
    } else {
      debugPrint('Connectivity changed: Offline');
      _updateStatus(true, 'Offline - Connection Required');
    }
  }

  Future<bool> checkServerHealth({bool silent = false}) async {
    if (_isChecking) return _isServerHealthy;

    if (!_connectivityService.isConnected) {
      return true;
    }

    _isChecking = true;

    if (!silent) {
      serverCheckingNotifier.value = true;
    }

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/health',
        options: Options(
          receiveTimeout: Duration(seconds: 3),
          sendTimeout: Duration(seconds: 3),
        ),
      );

      bool isHealthy = true;

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final status = response.data['status']?.toString().toUpperCase();
        isHealthy = status == 'UP' || status == 'HEALTHY' || status == 'OK';
      }

      _updateStatus(isHealthy, isHealthy ? 'Server Online' : 'Server Issues');
      return isHealthy;
    } catch (_) {
      _updateStatus(false, 'Server Offline');
      return false;
    } finally {
      _isChecking = false;
      _hasCompletedInitialCheck = true;

      if (!silent) {
        serverCheckingNotifier.value = false;
      }
    }
  }

  void stopHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _connectivityService.connectionNotifier.removeListener(
      _onConnectivityChanged,
    );
  }

  void dispose() {
    _healthCheckTimer?.cancel();
    _connectivityService.connectionNotifier.removeListener(
      _onConnectivityChanged,
    );
    serverHealthNotifier.dispose();
    serverStatusNotifier.dispose();
  }

}
