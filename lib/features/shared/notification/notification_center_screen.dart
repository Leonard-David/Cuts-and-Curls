import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/notification_model.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
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

    return Scaffold(
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(notificationProvider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: AppColors.textSecondary),
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

  Widget _buildNotificationsList(NotificationProvider notificationProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: Column(
        children: [
          // Stats header
          _buildStatsHeader(notificationProvider),
          // Notifications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return _buildNotificationItem(
                    notification, notificationProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(NotificationProvider notificationProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            notificationProvider.notifications.length.toString(),
            Icons.notifications,
            AppColors.primary,
          ),
          _buildStatItem(
            'Unread',
            notificationProvider.unreadNotifications.length.toString(),
            Icons.mark_email_unread,
            AppColors.accent,
          ),
          _buildStatItem(
            'Today',
            notificationProvider.todaysNotifications.length.toString(),
            Icons.today,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
      AppNotification notification, NotificationProvider notificationProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead
          ? AppColors.surfaceLight
          : AppColors.primary.withOpacity(0.05),
      elevation: 1,
      child: ListTile(
        leading: _buildNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
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
          _handleNotificationTap(notification, notificationProvider);
        },
        onLongPress: () {
          _showNotificationOptions(notification, notificationProvider);
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

  void _handleNotificationTap(
      AppNotification notification, NotificationProvider notificationProvider) {
    if (!notification.isRead) {
      notificationProvider.markAsRead(notification.id);
    }

    // Navigate based on notification type and relatedId
    switch (notification.type) {
      case NotificationType.appointment:
        _handleAppointmentNotification(notification);
        break;
      case NotificationType.payment:
        _handlePaymentNotification(notification);
        break;
      case NotificationType.reminder:
        _handleReminderNotification(notification);
        break;
      default:
        // Do nothing for other notifications
        break;
    }
  }

  void _handleAppointmentNotification(AppNotification notification) {
    // Navigate to appointment details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening appointment: ${notification.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handlePaymentNotification(AppNotification notification) {
    // Navigate to payment details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening payment details'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReminderNotification(AppNotification notification) {
    // Handle reminder notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment reminder'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _showNotificationOptions(
      AppNotification notification, NotificationProvider notificationProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                ListTile(
                  leading:
                      Icon(Icons.mark_email_read, color: AppColors.primary),
                  title: const Text('Mark as Read'),
                  onTap: () {
                    Navigator.pop(context);
                    notificationProvider.markAsRead(notification.id);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotification(notification.id, notificationProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNotification(
      String notificationId, NotificationProvider notificationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationProvider.deleteNotification(notificationId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted'),
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

  void _showClearAllDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final notificationProvider = context.read<NotificationProvider>();
              notificationProvider.clearAllNotifications(userId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
