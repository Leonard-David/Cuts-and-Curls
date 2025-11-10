// connectivity_snackbar.dart - COMPLETELY FIXED VERSION
import 'package:flutter/material.dart';

enum ConnectivityStatus {
  online,
  offline,
  slow,
  poor,
  unknown
}

class ConnectivitySnackBar {
  static void show({
    required BuildContext context,
    required ConnectivityStatus status,
    int durationSeconds = 4,
  }) {
    final overlay = Overlay.of(context);
    
    // Create a variable to hold the dismiss function
    VoidCallback? dismissCallback;
    
    // Declare overlayEntry first
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => _ConnectivityOverlay(
        status: status,
        duration: Duration(seconds: durationSeconds),
        onDismiss: () {
          dismissCallback?.call();
        },
      ),
    );
    
    // Now define the dismiss callback that uses overlayEntry
    dismissCallback = () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    };
    
    // Insert the overlay
    overlay.insert(overlayEntry);
    
    // Auto-remove after duration
    Future.delayed(Duration(seconds: durationSeconds), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ConnectivityOverlay extends StatefulWidget {
  final ConnectivityStatus status;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ConnectivityOverlay({
    required this.status,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<_ConnectivityOverlay> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    _controller.forward();
    
    // Auto-dismiss
    Future.delayed(widget.duration - const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return Colors.green.shade600;
      case ConnectivityStatus.offline:
        return Colors.red.shade600;
      case ConnectivityStatus.slow:
      case ConnectivityStatus.poor:
        return Colors.orange.shade600;
      case ConnectivityStatus.unknown:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return Icons.wifi;
      case ConnectivityStatus.offline:
        return Icons.wifi_off;
      case ConnectivityStatus.slow:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case ConnectivityStatus.poor:
        return Icons.signal_cellular_alt_1_bar;
      case ConnectivityStatus.unknown:
        return Icons.help;
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return 'Connection Restored';
      case ConnectivityStatus.offline:
        return 'No Internet Connection';
      case ConnectivityStatus.slow:
        return 'Slow Connection';
      case ConnectivityStatus.poor:
        return 'Unstable Connection';
      case ConnectivityStatus.unknown:
        return 'Connection Status Unknown';
    }
  }

  String _getStatusMessage() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return 'You\'re back online. All features are available.';
      case ConnectivityStatus.offline:
        return 'Please check your internet connection. Some features may be limited.';
      case ConnectivityStatus.slow:
        return 'Network is slower than usual. Loading may take longer.';
      case ConnectivityStatus.poor:
        return 'Weak signal detected. Connection may be unstable.';
      case ConnectivityStatus.unknown:
        return 'Unable to determine your connection status.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatusMessage(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () {
                      _controller.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}