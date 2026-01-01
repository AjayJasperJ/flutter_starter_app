import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;
  Stream<bool> get connectionChange => _connectionChangeController.stream;

  Future<void> init() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _checkConnection(results);
    _connectivity.onConnectivityChanged.listen(_checkConnection);
  }

  Future<void> _checkConnection(List<ConnectivityResult> results) async {
    bool previousConnection = _hasConnection;
    // If any result in the list is NOT none, we assume we might have connection.
    bool hasNetworkInterface = results.any((r) => r != ConnectivityResult.none);
    bool currentConnection = false;

    if (hasNetworkInterface) {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          currentConnection = true;
        }
      } on SocketException catch (_) {
        currentConnection = false;
      }
    }

    if (previousConnection != currentConnection) {
      _hasConnection = currentConnection;
      _connectionChangeController.add(_hasConnection);
    }
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
