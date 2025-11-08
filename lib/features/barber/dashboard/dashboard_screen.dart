import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/models/notification_model.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AppointmentsProvider _appointmentsProvider;
  late NotificationProvider _notificationProvider;
  Map<String, dynamic> _earningsData = {
    'todayEarnings': 0.0,
    'totalEarnings': 0.0,
    'todayAppointments': 0,
    'pendingAppointments': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        _appointmentsProvider = context.read<AppointmentsProvider>();
        _notificationProvider = context.read<NotificationProvider>();

        // Load appointments and notifications
        _appointmentsProvider.refreshBarberData(authProvider.user!.id);
        _notificationProvider.loadNotifications(authProvider.user!.id);

        // Start real-time earnings tracking
        _startEarningsTracking(authProvider.user!.id);
      }
    });
  }

  void _startEarningsTracking(String barberId) {
    // Real-time earnings stream
    FirebaseFirestore.instance
        .collection('payments')
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      _calculateRealTimeEarnings(snapshot.docs, barberId);
    });
  }

  void _calculateRealTimeEarnings(List<QueryDocumentSnapshot> paymentDocs, String barberId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    double todayEarnings = 0.0;
    double totalEarnings = 0.0;

    // Calculate earnings from payments
    for (final doc in paymentDocs) {
      final payment = doc.data() as Map<String, dynamic>;
      final amount = payment['amount']?.toDouble() ?? 0.0;
      final completedAt = payment['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(payment['completedAt'])
          : null;

      totalEarnings += amount;

      // Today's earnings (only from today's completed payments)
      if (completedAt != null && 
          completedAt.isAfter(today) && 
          completedAt.isBefore(tomorrow)) {
        todayEarnings += amount;
      }
    }

    // Get appointment counts from provider
    final appointments = _appointmentsProvider.allAppointments;
    final metrics = _calculateAppointmentMetrics(appointments);

    if (mounted) {
      setState(() {
        _earningsData = {
          'todayEarnings': todayEarnings,
          'totalEarnings': totalEarnings,
          'todayAppointments': metrics.todayAppointments,
          'pendingAppointments': metrics.pendingAppointments,
        };
      });
    }
  }

  DashboardMetrics _calculateAppointmentMetrics(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int todayAppointments = 0;
    int pendingAppointments = 0;

    for (final appointment in appointments) {
      final appointmentDate = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );

      // Count today's appointments (only confirmed and pending for today)
      if (appointmentDate == today &&
          (appointment.status == 'confirmed' || appointment.status == 'pending')) {
        todayAppointments++;
      }

      // Count pending appointments (all non-completed, non-cancelled)
      if (appointment.status != 'completed' && appointment.status != 'cancelled') {
        pendingAppointments++;
      }
    }

    return DashboardMetrics(
      todayAppointments: todayAppointments,
      pendingAppointments: pendingAppointments,
      todayEarnings: _earningsData['todayEarnings'],
      totalEarnings: _earningsData['totalEarnings'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appointmentsProvider = Provider.of<AppointmentsProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final appointments = appointmentsProvider.allAppointments;
    final metrics = _calculateAppointmentMetrics(appointments);

    return RefreshIndicator(
      onRefresh: () async {
        if (authProvider.user != null) {
          appointmentsProvider.refreshBarberData(authProvider.user!.id);
          notificationProvider.loadNotifications(authProvider.user!.id);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(authProvider),
            const SizedBox(height: 24),

            // Real-time Metrics Grid
            _buildMetricsGrid(metrics),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Today's Appointments
            _buildTodaysAppointments(appointmentsProvider.todaysAppointments),
            const SizedBox(height: 24),

            // Recent Activity/Notifications
            _buildRecentActivity(notificationProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${authProvider.user?.fullName ?? 'Professional'}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s your real-time business overview',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('payments')
                      .where('barberId', isEqualTo: authProvider.user?.id)
                      .where('status', isEqualTo: 'completed')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final lastUpdated = snapshot.hasData 
                        ? 'Updated just now' 
                        : 'Loading...';
                    return Text(
                      lastUpdated,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardMetrics metrics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          title: 'Appointments',
          value: metrics.todayAppointments.toString(),
          icon: Icons.calendar_today_rounded,
          color: AppColors.primary,
          subtitle: 'Scheduled for today',
          isLive: true,
        ),
        _buildMetricCard(
          title: 'Pending',
          value: metrics.pendingAppointments.toString(),
          icon: Icons.pending_actions_rounded,
          color: AppColors.accent,
          subtitle: 'Awaiting action',
          isLive: true,
        ),
        _buildMetricCard(
          title: 'Today\'s Earnings',
          value: 'N\$${metrics.todayEarnings.toStringAsFixed(2)}',
          icon: Icons.attach_money_rounded,
          color: Colors.green,
          subtitle: 'Today\'s income',
          isLive: true,
        ),
        _buildMetricCard(
          title: 'Total Earnings',
          value: 'N\$${metrics.totalEarnings.toStringAsFixed(2)}',
          icon: Icons.bar_chart_rounded,
          color: Colors.purple,
          subtitle: 'All-time completed',
          isLive: false,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isLive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'New Appointment',
                color: AppColors.primary,
                onTap: () {
                  // Navigate to create appointment
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.chat_outlined,
                title: 'Messages',
                color: Colors.blue,
                onTap: () {
                  // Navigate to messages
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysAppointments(List<AppointmentModel> todaysAppointments) {
    final upcomingAppointments = todaysAppointments
        .where((appointment) => appointment.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              '${upcomingAppointments.length} appointments',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingAppointments.isEmpty)
          _buildEmptyState(
            icon: Icons.schedule_rounded,
            title: 'No upcoming appointments',
            message: 'You\'re all caught up for today!',
          )
        else
          Column(
            children: upcomingAppointments.take(3).map((appointment) {
              return _buildAppointmentItem(appointment);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAppointmentItem(AppointmentModel appointment) {
    final timeUntil = appointment.date.difference(DateTime.now());
    final hoursUntil = timeUntil.inHours;
    final minutesUntil = timeUntil.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: _getStatusColor(appointment.status),
          ),
        ),
        title: Text(
          appointment.clientName ?? 'Client',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appointment.serviceName ?? 'Service'),
            Text(
              '${DateFormat('h:mm a').format(appointment.date)} • '
              '${hoursUntil > 0 ? '${hoursUntil}h ' : ''}${minutesUntil}m',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            appointment.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _getStatusColor(appointment.status),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(NotificationProvider notificationProvider) {
    final recentNotifications =
        notificationProvider.notifications.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            if (notificationProvider.hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'New',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentNotifications.isEmpty)
          _buildEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No recent activity',
            message: 'Your notifications will appear here',
          )
        else
          Column(
            children: recentNotifications.map((notification) {
              return _buildNotificationItem(notification);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: notification.isRead
          ? AppColors.background
          : AppColors.primary.withOpacity(0.05),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            size: 16,
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notification.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.accent;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return AppColors.primary;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.reminder:
        return AppColors.accent;
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.reminder:
        return Icons.access_time;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
    }
  }
}

class DashboardMetrics {
  final int todayAppointments;
  final int pendingAppointments;
  final double todayEarnings;
  final double totalEarnings;

  DashboardMetrics({
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.todayEarnings,
    required this.totalEarnings,
  });
}