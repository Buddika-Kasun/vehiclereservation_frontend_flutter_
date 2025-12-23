// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> connectionStatusNotifier = ValueNotifier<String>(
    'Online',
  );

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;

    _isConnected = result != ConnectivityResult.none;
    connectionNotifier.value = _isConnected;

    if (_isConnected) {
      connectionStatusNotifier.value = 'Online';
    } else {
      connectionStatusNotifier.value = 'Offline';
    }

    // Only notify if status changed
    if (wasConnected != _isConnected) {
      debugPrint(
        'Connectivity changed: ${_isConnected ? 'Online' : 'Offline'}',
      );
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    connectionNotifier.dispose();
    connectionStatusNotifier.dispose();
  }
}
