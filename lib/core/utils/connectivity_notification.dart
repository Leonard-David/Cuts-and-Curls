import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sheersync/core/constants/colors.dart';

enum ConnectivityStatus {
  online,
  offline,
  slow,
  poor,
  unknown
}

class ConnectivityNotification extends StatefulWidget {
  const ConnectivityNotification({super.key});

  @override
  State<ConnectivityNotification> createState() => _ConnectivityNotificationState();
}

class _ConnectivityNotificationState extends State<ConnectivityNotification> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  void _showNotification(ConnectivityStatus status) {
    if (_currentStatus == status && _isVisible) return;
    
    _currentStatus = status;
    _isVisible = true;
    _animationController.forward();
    
    // Auto-hide after 3 seconds for online status
    if (status == ConnectivityStatus.online) {
      Future.delayed(const Duration(seconds: 3), _hideNotification);
    }
  }

  void _hideNotification() {
    if (!_isVisible) return;
    
    _animationController.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
    });
  }

  Color _getStatusColor(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return Colors.green;
      case ConnectivityStatus.offline:
        return AppColors.error;
      case ConnectivityStatus.slow:
      case ConnectivityStatus.poor:
        return Colors.orange;
      case ConnectivityStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ConnectivityStatus status) {
    switch (status) {
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

  String _getStatusTitle(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return 'Back Online';
      case ConnectivityStatus.offline:
        return 'You\'re Offline';
      case ConnectivityStatus.slow:
        return 'Slow Connection';
      case ConnectivityStatus.poor:
        return 'Poor Connection';
      case ConnectivityStatus.unknown:
        return 'Connection Status';
    }
  }

  String _getStatusMessage(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return 'Your connection has been restored.';
      case ConnectivityStatus.offline:
        return 'Please check your internet connection.';
      case ConnectivityStatus.slow:
        return 'Network is slow. Some features may not work properly.';
      case ConnectivityStatus.poor:
        return 'Weak signal detected. Connection may be unstable.';
      case ConnectivityStatus.unknown:
        return 'Checking connection status...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Visibility(
            visible: _isVisible,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: child,
              ),
            ),
          );
        },
        child: _buildNotificationContent(),
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Material(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getStatusColor(_currentStatus).withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(_currentStatus),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusTitle(_currentStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusMessage(_currentStatus),
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
            if (_currentStatus != ConnectivityStatus.online)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _hideNotification,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }
}
