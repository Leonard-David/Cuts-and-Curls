import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/notification_model.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    
    if (authProvider.user != null) {
      notificationProvider.loadNotifications(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
        actions: [
          if (notificationProvider.hasUnread)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () {
                notificationProvider.markAllAsRead(authProvider.user!.id);
              },
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notificationProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationProvider.notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? AppColors.surfaceLight : AppColors.primary.withOpacity(0.05),
      elevation: 1,
      child: ListTile(
        leading: _buildNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          _handleNotificationTap(notification);
        },
        onLongPress: () {
          _showNotificationOptions(notification);
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.appointment:
        icon = Icons.calendar_today;
        color = AppColors.primary;
        break;
      case NotificationType.payment:
        icon = Icons.payment;
        color = AppColors.success;
        break;
      case NotificationType.reminder:
        icon = Icons.access_time;
        color = AppColors.accent;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer;
        color = Colors.purple;
        break;
      case NotificationType.system:
        icon = Icons.info;
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      final notificationProvider = context.read<NotificationProvider>();
      notificationProvider.markAsRead(notification.id);
    }

    // Navigate based on notification type and relatedId
    switch (notification.type) {
      case NotificationType.appointment:
        // Navigate to appointment details
        _handleAppointmentNotification(notification);
        break;
      case NotificationType.payment:
        // Navigate to payment details
        break;
      case NotificationType.promotion:
        // Navigate to promotions
        break;
      default:
        // Do nothing for system notifications
        break;
    }
  }

  void _handleAppointmentNotification(AppNotification notification) {
    // Navigate to appointment details screen
    // This would typically require fetching the appointment details
    // and navigating to the appropriate screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening appointment: ${notification.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showNotificationOptions(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                ListTile(
                  leading: Icon(Icons.mark_email_read, color: AppColors.primary),
                  title: const Text('Mark as Read'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<NotificationProvider>().markAsRead(notification.id);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotification(notification.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNotification(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification deleted'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              final notificationProvider = context.read<NotificationProvider>();
              notificationProvider.clearAllNotifications(authProvider.user!.id);
            },
            child: Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}