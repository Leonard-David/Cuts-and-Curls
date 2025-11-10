// connectivity_provider.dart - ENHANCED VERSION
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/widgets/connectivity_snackbar.dart';

class ConnectivityProvider with ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  // Global key for accessing context from anywhere
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ConnectivityStatus get status => _status;

  ConnectivityProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Initial connectivity check
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    ConnectivityStatus newStatus;

    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    if (!hasConnection) {
      newStatus = ConnectivityStatus.offline;
    } else {
      if (results.contains(ConnectivityResult.mobile) &&
          !results.contains(ConnectivityResult.wifi)) {
        newStatus = ConnectivityStatus.slow;
      } else {
        newStatus = ConnectivityStatus.online;
      }
    }

    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
      
      // Show global snackbar when status changes
      _showGlobalSnackbar(newStatus);
    }
  }

  void _showGlobalSnackbar(ConnectivityStatus status) {
    // Use the navigator key to show snackbar globally
    if (navigatorKey.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ConnectivitySnackBar.show(
          context: navigatorKey.currentContext!,
          status: status,
          durationSeconds: status == ConnectivityStatus.online ? 3 : 5,
        );
      });
    }
  }

  // Method to manually trigger snackbar for testing
  void showSnackbar(ConnectivityStatus status) {
    _showGlobalSnackbar(status);
  }

  // Method to manually set poor/slow connection for testing
  void setPoorConnection() {
    _status = ConnectivityStatus.poor;
    notifyListeners();
    _showGlobalSnackbar(_status);
  }

  void setSlowConnection() {
    _status = ConnectivityStatus.slow;
    notifyListeners();
    _showGlobalSnackbar(_status);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

// Updated wrapper with global key
class ConnectivityAwareApp extends StatelessWidget {
  final Widget child;

  const ConnectivityAwareApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ConnectivityProvider(),
      child: Consumer<ConnectivityProvider>(
        builder: (context, connectivityProvider, child) {
          return Stack(
            children: [
              // Your main app content
              child!,
            ],
          );
        },
        child: child,
      ),
    );
  }
}

// Global method to show connectivity snackbar from anywhere
void showGlobalConnectivitySnackbar(ConnectivityStatus status) {
  if (ConnectivityProvider.navigatorKey.currentContext != null) {
    ConnectivitySnackBar.show(
      context: ConnectivityProvider.navigatorKey.currentContext!,
      status: status,
      durationSeconds: status == ConnectivityStatus.online ? 3 : 5,
    );
  }
}