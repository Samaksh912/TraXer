import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'sync_service.dart';

class ConnectivitySyncTrigger {
  ConnectivitySyncTrigger({
    required this.syncService,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final SyncService syncService;
  final Connectivity _connectivity;

  DateTime? _lastSyncAt;
  StreamSubscription<dynamic>? _subscription;
  bool _isRunning = false;

  void init() {
    unawaited(_checkInitialConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen((dynamic result) {
      if (_isOnline(result)) {
        unawaited(_triggerSyncIfAllowed());
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (_isOnline(result)) {
      await _triggerSyncIfAllowed();
    }
  }

  Future<void> _triggerSyncIfAllowed() async {
    final now = DateTime.now();
    if (_isRunning) {
      return;
    }

    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!) < const Duration(seconds: 3)) {
      return;
    }

    _isRunning = true;
    _lastSyncAt = now;

    try {
      await syncService.syncPendingItems();
    } finally {
      _isRunning = false;
    }
  }

  bool _isOnline(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    if (result is List<ConnectivityResult>) {
      return result.any((entry) => entry != ConnectivityResult.none);
    }

    return false;
  }
}
