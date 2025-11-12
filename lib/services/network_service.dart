import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkService {
  static NetworkService? _instance;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  NetworkService._internal() {
    _init();
  }

  factory NetworkService() {
    _instance ??= NetworkService._internal();
    return _instance!;
  }

  Future<void> _init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(result);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _isOnline = _hasConnection(results);
      },
    );
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(result);
    return _isOnline;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

