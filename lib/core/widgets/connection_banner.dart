// lib/core/widgets/connection_banner.dart
import 'package:flutter/material.dart';
import 'package:sheersync/core/constants/colors.dart';

class ConnectionBanner extends StatelessWidget {
  final bool isConnected;
  final bool isOfflineMode;

  const ConnectionBanner({
    super.key,
    required this.isConnected,
    required this.isOfflineMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected && !isOfflineMode) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isConnected ? Colors.orange : AppColors.error,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected 
                ? 'Slow connection - messages may be delayed'
                : 'You are offline - messages will send when connected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}