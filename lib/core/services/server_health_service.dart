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

  Future<bool> checkServerHealth() async {
    // Don't check server if we're offline
    if (!_connectivityService.isConnected) {
      return false;
    }

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/health',
        options: Options(
          receiveTimeout: Duration(seconds: 3), // Shorter timeout
          sendTimeout: Duration(seconds: 3),
        ),
      );

      final healthy = response.statusCode == 200;
      _updateStatus(healthy, healthy ? 'Server Online' : 'Server Issues');
      return healthy;
    } catch (e) {
      _updateStatus(false, 'Server Offline');
      return false;
    }
  }

  void _updateStatus(bool isHealthy, String status) {
    _isServerHealthy = isHealthy;
    serverHealthNotifier.value = isHealthy;
    serverStatusNotifier.value = status;
  }

  void startHealthMonitoring({int intervalSeconds = 30}) {
    // Listen to connectivity changes
    _connectivityService.connectionNotifier.addListener(_onConnectivityChanged);

    // Set initial status based on connectivity
    if (_connectivityService.isConnected) {
      checkServerHealth();
    } else {
      // When offline, reset to healthy state so it doesn't show "Server Maintenance"
      _updateStatus(true, 'Offline - Connection Required');
    }

    // Set up periodic checks
    _healthCheckTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
      timer,
    ) async {
      if (_connectivityService.isConnected) {
        await checkServerHealth();
      }
    });
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isConnected) {
      // Just came online, check server immediately
      checkServerHealth();
    } else {
      // Went offline, reset to healthy state
      _updateStatus(true, 'Offline - Connection Required');
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
