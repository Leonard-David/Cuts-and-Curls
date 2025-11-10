import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/utils/connectivity_notification.dart';
import 'package:sheersync/core/widgets/connection_banner.dart';
import 'package:sheersync/data/models/notification_model.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/providers/connectivity_provider.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

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
  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    Provider.of<ConnectivityProvider>(context); // Add this provider

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Connection Banner for notification screen too
              if (!chatProvider.isConnected)
                ConnectionBanner(
                  isConnected: chatProvider.isConnected,
                  isOfflineMode: chatProvider.isOfflineMode,
                ),

              // Rest of your notification center content
              Expanded(
                child: notificationProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildNotificationContent(notificationProvider),
              ),
            ],
          ),

          // Global connectivity notification
          ConnectivityNotification(),
        ],
      ),
    );
  }

  Widget _buildNotificationContent(NotificationProvider notificationProvider) {
    final filteredNotifications =
        _getFilteredNotifications(notificationProvider);

    return Column(
      children: [
        // Stats header
        _buildStatsHeader(notificationProvider),

        // Category filter chips
        _buildCategoryFilter(notificationProvider),

        // Notifications list
        Expanded(
          child: filteredNotifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadNotifications();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationItem(
                          notification, notificationProvider);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(NotificationProvider notificationProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.accent.withOpacity(0.6),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            notificationProvider.totalCount.toString(),
            Icons.notifications,
            Colors.white,
          ),
          _buildStatItem(
            'Unread',
            notificationProvider.unreadCount.toString(),
            Icons.mark_email_unread,
            Colors.amber[300]!,
          ),
          _buildStatItem(
            'Today',
            notificationProvider.todaysCount.toString(),
            Icons.today,
            Colors.lightGreen[300]!,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(NotificationProvider notificationProvider) {
    final categories = NotificationCategory.values;
    final counts = notificationProvider.notificationCountsByCategory;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final count = counts[category] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${_getCategoryLabel(category)} ($count)'),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory =
                        selected ? category : NotificationCategory.all;
                  });
                },
                backgroundColor: AppColors.surfaceLight,
                selectedColor: AppColors.primary.withOpacity(0.1),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _selectedCategory == category
                      ? AppColors.primary
                      : AppColors.text,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getCategoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.today:
        return 'Today';
      case NotificationCategory.thisWeek:
        return 'This Week';
      case NotificationCategory.thisMonth:
        return 'This Month';
      case NotificationCategory.older:
        return 'Older';
      case NotificationCategory.all:
        return 'All';
    }
  }

  List<AppNotification> _getFilteredNotifications(
      NotificationProvider notificationProvider) {
    if (_selectedCategory == NotificationCategory.all) {
      return notificationProvider.notifications;
    }

    return notificationProvider.notifications
        .where((notification) => notification.category == _selectedCategory)
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off,
              size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_selectedCategory) {
      case NotificationCategory.today:
        return 'No notifications for today';
      case NotificationCategory.thisWeek:
        return 'No notifications this week';
      case NotificationCategory.thisMonth:
        return 'No notifications this month';
      case NotificationCategory.older:
        return 'No older notifications';
      case NotificationCategory.all:
        return 'You\'re all caught up! Check back later for new notifications.';
    }
  }

  Widget _buildNotificationItem(
      AppNotification notification, NotificationProvider notificationProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead
          ? AppColors.surfaceLight // Subtle background for read
          : AppColors.primary.withOpacity(0.05), // Highlight for unread
      elevation: notification.isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary
                  .withOpacity(0.3), // Stronger border for unread
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildNotificationIcon(notification.type, notification.isRead),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
            color: AppColors.text,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatNotificationTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (notification.readAt != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.done_all, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Read',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (!notification.isSynced) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.sync_disabled, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
            : null,
        onTap: () {
          // Immediate mark as read on tap
          if (!notification.isRead) {
            notificationProvider.markAsRead(notification.id);
          }
          _handleNotificationAction(notification);
        },
        onLongPress: () {
          _showNotificationOptions(notification, notificationProvider);
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, bool isRead) {
    IconData icon;
    Color color;
    String tooltip;

    switch (type) {
      case NotificationType.appointment:
        icon = Icons.calendar_today;
        color = isRead ? AppColors.textSecondary : AppColors.primary;
        tooltip = 'Appointment';
        break;
      case NotificationType.payment:
        icon = Icons.payment;
        color = isRead ? AppColors.textSecondary : Colors.green;
        tooltip = 'Payment';
        break;
      case NotificationType.reminder:
        icon = Icons.access_time;
        color = isRead ? AppColors.textSecondary : Colors.orange;
        tooltip = 'Reminder';
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer;
        color = isRead ? AppColors.textSecondary : Colors.purple;
        tooltip = 'Promotion';
        break;
      case NotificationType.system:
        icon = Icons.info;
        color = isRead ? AppColors.textSecondary : Colors.blue;
        tooltip = 'System';
        break;
      case NotificationType.marketing:
        icon = Icons.campaign;
        color = isRead ? AppColors.textSecondary : Colors.pink;
        tooltip = 'Marketing';
        break;
      case NotificationType.availability:
        icon = Icons.schedule;
        color = isRead ? AppColors.textSecondary : Colors.teal;
        tooltip = 'Availability';
        break;
      case NotificationType.discount:
        icon = Icons.discount;
        color = isRead ? AppColors.textSecondary : Colors.red;
        tooltip = 'Discount';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(isRead ? 0.05 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  String _formatNotificationTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(notificationDate).inDays;

    if (difference == 0) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference <= 7) {
      return DateFormat('EEEE at h:mm a').format(date);
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    }
  }

  void _handleNotificationAction(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.appointment:
        _navigateToAppointment(notification);
        break;
      case NotificationType.payment:
        _navigateToPayment(notification);
        break;
      case NotificationType.reminder:
        _handleReminder(notification);
        break;
      case NotificationType.promotion:
      case NotificationType.marketing:
      case NotificationType.discount:
        _showPromotionDetails(notification);
        break;
      case NotificationType.availability:
        _navigateToAvailability(notification);
        break;
      default:
        _showNotificationDetails(notification);
        break;
    }
  }

  void _navigateToAppointment(AppNotification notification) {
    // Navigate to appointment details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening appointment: ${notification.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToPayment(AppNotification notification) {
    // Navigate to payment details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening payment details'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReminder(AppNotification notification) {
    // Handle reminder action
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAppointment(notification);
            },
            child: const Text('View Appointment'),
          ),
        ],
      ),
    );
  }

  void _showPromotionDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            if (notification.data != null) ...[
              const SizedBox(height: 16),
              const Text('Promotion Details:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...notification.data!.entries
                  .map((entry) => Text('${entry.key}: ${entry.value}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply promotion or navigate to relevant screen
            },
            child: const Text('Use Offer'),
          ),
        ],
      ),
    );
  }

  void _navigateToAvailability(AppNotification notification) {
    // Navigate to availability management
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening availability settings'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Type: ${notification.type.name}'),
              Text(
                  'Time: ${DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt)}'),
              Text('Status: ${notification.isRead ? 'Read' : 'Unread'}'),
              Text('Synced: ${notification.isSynced ? 'Yes' : 'No'}'),
              if (notification.relatedId != null)
                Text('Related ID: ${notification.relatedId}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
              ListTile(
                leading: Icon(Icons.info, color: AppColors.primary),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showNotificationDetails(notification);
                },
              ),
              if (!notification.isRead)
                ListTile(
                  leading:
                      Icon(Icons.mark_email_read, color: AppColors.primary),
                  title: const Text('Mark as Read'),
                  onTap: () {
                    Navigator.pop(context);
                    notificationProvider.markAsRead(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification marked as read'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Delete Permanently',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotificationPermanently(
                      notification.id, notificationProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNotificationPermanently(
      String notificationId, NotificationProvider notificationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: const Text(
            'This notification will be deleted from all devices and cannot be recovered. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationProvider
                  .permanentlyDeleteNotification(notificationId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted permanently'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete Forever',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
