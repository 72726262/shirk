import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus {
  online,
  offline,
}

/// Service for monitoring network connectivity
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<NetworkStatus> _statusController = StreamController<NetworkStatus>.broadcast();
  
  NetworkStatus _currentStatus = NetworkStatus.online;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Get current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Initialize network monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    final newStatus = hasConnection ? NetworkStatus.online : NetworkStatus.offline;
    
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      
      if (kDebugMode) {
        print('Network Status Changed: ${_currentStatus == NetworkStatus.online ? "Online" : "Offline"}');
      }
    }
  }

  /// Check if device is currently online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
