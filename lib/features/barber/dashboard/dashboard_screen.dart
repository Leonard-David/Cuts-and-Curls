import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/appointment_model.dart';
import '../../../features/auth/controllers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _todayAppointments = 0;
  int _pendingAppointments = 0;
  double _todayEarnings = 0.0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final barberId = authProvider.user?.id;
    
    if (barberId == null) return;

    // Get today's date for filtering
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Fetch today's appointments
    final todayQuery = FirebaseFirestore.instance
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .where('date', isLessThanOrEqualTo: todayEnd);

    final allAppointmentsQuery = FirebaseFirestore.instance
        .collection('appointments')
        .where('barberId', isEqualTo: barberId);

    // Listen to real-time updates
    todayQuery.snapshots().listen((snapshot) {
      setState(() {
        _todayAppointments = snapshot.docs.length;
      });
    });

    allAppointmentsQuery.snapshots().listen((snapshot) {
      int pending = 0;
      double totalEarnings = 0.0;
      double todayEarnings = 0.0;

      for (var doc in snapshot.docs) {
        final appointment = AppointmentModel.fromMap(doc.data());
        
        if (appointment.status == 'pending') {
          pending++;
        }

        if (appointment.status == 'completed' && appointment.price != null) {
          totalEarnings += appointment.price!;
          
          // Check if completed today
          if (appointment.date.isAfter(todayStart)) {
            todayEarnings += appointment.price!;
          }
        }
      }

      setState(() {
        _pendingAppointments = pending;
        _totalEarnings = totalEarnings;
        _todayEarnings = todayEarnings;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            
            const SizedBox(height: 24),
            
            // Stats Grid
            _buildStatsGrid(),
            
            const SizedBox(height: 24),
            
            // Today's Appointments
            _buildTodaysAppointments(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
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
            user?.fullName ?? 'Barber',
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

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Today\'s Appointments',
          _todayAppointments.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatCard(
          'Pending',
          _pendingAppointments.toString(),
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          'Today\'s Earnings',
          'N\$${_todayEarnings.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'Total Earnings',
          'N\$${_totalEarnings.toStringAsFixed(2)}',
          Icons.bar_chart,
          Colors.purple,
        ),
      ],
    );
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
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: Provider.of<AuthProvider>(context).user?.id)
          .where('date', isGreaterThanOrEqualTo: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
          .where('date', isLessThan: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1))
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No appointments today',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final appointments = snapshot.data!.docs;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Appointments",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Add Service',
                    Icons.add,
                    Colors.blue,
                    () {
                      // Navigate to add service
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Set Availability',
                    Icons.access_time,
                    Colors.green,
                    () {
                      // Navigate to availability settings
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'View Earnings',
                    Icons.analytics,
                    Colors.orange,
                    () {
                      // Navigate to earnings
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Client Reviews',
                    Icons.star,
                    Colors.purple,
                    () {
                      // Navigate to reviews
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

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
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