import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  Color backgroundColor;
  IconData icon;

  switch (type) {
    case SnackBarType.success:
      backgroundColor = Colors.green;
      icon = Icons.check_circle_outline;
      break;
    case SnackBarType.error:
      backgroundColor = Colors.red;
      icon = Icons.error_outline;
      break;
    case SnackBarType.warning:
      backgroundColor = Colors.orange;
      icon = Icons.warning_amber_outlined;
      break;
    case SnackBarType.info:
      backgroundColor = Colors.blue;
      icon = Icons.info_outline;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      duration: duration,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}