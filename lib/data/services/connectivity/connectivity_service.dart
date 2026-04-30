import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static const _probeUris = [
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://clients3.google.com/generate_204',
  ];

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _internetStatusController =
      StreamController<bool>.broadcast();
  Timer? _pollingTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _lastStatus = false;
  bool _hasReportedStatus = false;

  Stream<bool> get internetStatus => _internetStatusController.stream;

  ConnectivityService() {
    // Start monitoring connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_checkInternetAccess);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkInternetAccess(null),
    );
    // Initial check
    _checkInternetAccess(null);
  }

  void dispose() {
    _pollingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _internetStatusController.close();
  }

  Future<void> _checkInternetAccess(
      ConnectivityResult? connectivityResult) async {
    if (connectivityResult == ConnectivityResult.none) {
      _updateStatus(false);
      return;
    }

    try {
      for (final probeUri in _probeUris) {
        final response = await http.get(Uri.parse(probeUri)).timeout(
              const Duration(seconds: 5),
            );
        if (response.statusCode == 204 ||
            (response.statusCode == 200 && response.body.trim().isEmpty)) {
          _updateStatus(true);
          return;
        }
      }

      _updateStatus(false);
    } on TimeoutException catch (_) {
      _updateStatus(false);
    } on SocketException catch (_) {
      _updateStatus(false);
    } catch (e) {
      debugPrint('Error checking internet access: $e');
      _updateStatus(false);
    }
  }

  void _updateStatus(bool hasInternet) {
    if (!_hasReportedStatus || _lastStatus != hasInternet) {
      _hasReportedStatus = true;
      _lastStatus = hasInternet;
      _internetStatusController.add(hasInternet);
    }
  }

  /// Check current internet connectivity
  Future<bool> checkInternetAccess() async {
    return _lastStatus;
  }
}
