import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
import 'package:sheersync/features/barber/appointments/create_appointment_screen.dart';
import 'package:sheersync/features/barber/earnings/barber_earning_screen.dart';
import 'package:sheersync/features/barber/marketing/marketing_screen.dart';
import 'package:sheersync/features/barber/services/barber_services_screen.dart';
import 'package:sheersync/features/barber/services/manage_availability_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      return _buildErrorState('Please log in to view your dashboard.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(authProvider),
          const SizedBox(height: 24),

          // Real-time Stats Grid
          _buildStatsGrid(barberId),
          const SizedBox(height: 24),

          // Today's Appointments - Real-time
          _buildTodaysAppointments(barberId),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    final user = authProvider.user;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.fullName ?? 'Professional',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to make your clients look great?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String barberId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingStats();
        }

        final appointments = snapshot.data!.docs;
        final stats = _calculateStats(appointments);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Today\'s Appointments',
              stats['todayAppointments'].toString(),
              Icons.calendar_today,
              AppColors.primary,
            ),
            _buildStatCard(
              'Pending',
              stats['pendingAppointments'].toString(),
              Icons.pending_actions,
              AppColors.accent,
            ),
            _buildStatCard(
              'Today\'s Earnings',
              'N\$${stats['todayEarnings'].toStringAsFixed(2)}',
              Icons.attach_money,
              AppColors.success,
            ),
            _buildStatCard(
              'Total Earnings',
              'N\$${stats['totalEarnings'].toStringAsFixed(2)}',
              Icons.bar_chart,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> appointments) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    int todayAppointments = 0;
    int pendingAppointments = 0;
    double todayEarnings = 0.0;
    double totalEarnings = 0.0;

    for (var doc in appointments) {
      final appointment = AppointmentModel.fromMap(doc.data() as Map<String, dynamic>);

      // Today's appointments
      if (appointment.date.isAfter(todayStart)) {
        todayAppointments++;
      }

      // Pending appointments
      if (appointment.status == 'pending') {
        pendingAppointments++;
      }

      // Earnings calculations
      if (appointment.status == 'completed' && appointment.price != null) {
        totalEarnings += appointment.price!;

        if (appointment.date.isAfter(todayStart)) {
          todayEarnings += appointment.price!;
        }
      }
    }

    return {
      'todayAppointments': todayAppointments,
      'pendingAppointments': pendingAppointments,
      'todayEarnings': todayEarnings,
      'totalEarnings': totalEarnings,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(4, (index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: 60,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 80,
                  color: Colors.grey[200],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTodaysAppointments(String barberId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: todayStart.millisecondsSinceEpoch)
          .where('date', isLessThanOrEqualTo: todayEnd.millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date')
          .snapshots(), // REAL-TIME STREAM
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingAppointments();
        }

        if (snapshot.hasError) {
          return _buildErrorAppointments(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyAppointments();
        }

        final appointments = snapshot.data!.docs;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Appointments",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${appointments.length}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...appointments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final appointment = AppointmentModel.fromMap(data);
                  return _buildAppointmentItem(appointment);
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentItem(AppointmentModel appointment) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(appointment.status),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getStatusIcon(appointment.status),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        appointment.clientName ?? 'Client',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${_formatTime(appointment.date)} • ${appointment.serviceName ?? 'Service'}',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Text(
        'N\$${appointment.price?.toStringAsFixed(2) ?? '0.00'}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            
            // First Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Create Appointment',
                    Icons.add_circle,
                    AppColors.primary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAppointmentScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Manage Services',
                    Icons.construction,
                    AppColors.primary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarberServicesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Second Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Manage Appointments',
                    Icons.calendar_month,
                    AppColors.success,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarberAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Set Availability',
                    Icons.access_time,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageAvailabilityScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Third Row - MARKETING ACTIONS
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Marketing Tools',
                    Icons.campaign,
                    AppColors.accent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarketingScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'View Earnings',
                    Icons.analytics,
                    AppColors.accent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarberEarningScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingAppointments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Appointments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorAppointments(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Appointments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading appointments',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Appointments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No appointments scheduled for today.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}