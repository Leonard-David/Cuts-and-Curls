import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cutscurls/features/barber/earnings/barber_earning_screen.dart';
import 'package:cutscurls/features/barber/services/barber_services_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../appointments/barber_appointments_screen.dart';


class BarberDashboardScreen extends StatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  State<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends State<BarberDashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _loading = true;

  int totalAppointments = 0;
  int completedAppointments = 0;
  int pendingAppointments = 0;
  double totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: user!.uid)
          .get();

      totalAppointments = snapshot.docs.length;
      completedAppointments = snapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;
      pendingAppointments = snapshot.docs
          .where((doc) => doc['status'] == 'pending')
          .length;

      totalEarnings = snapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .fold(0.0, (sum, doc) => sum + (doc['price'] as num).toDouble());

      setState(() => _loading = false);
    } catch (e, st) {
      debugPrint('Dashboard load error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dashboard data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a barber.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Barber Dashboard'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back 👋',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Stats Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard('Total', totalAppointments, Colors.blue),
                      _buildStatCard('Pending', pendingAppointments, Colors.orange),
                      _buildStatCard('Completed', completedAppointments, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Earnings Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActionTile(
                    context,
                    title: 'View Appointments',
                    icon: Icons.calendar_today,
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarberAppointmentsScreen(),
                      ),
                    ),
                  ),
                  _buildActionTile(
                    context,
                    title: 'Manage Services',
                    icon: Icons.cut,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarberServicesScreen(),
                      ),
                    ),
                  ),
                  _buildActionTile(
                    context,
                    title: 'View Earnings',
                    icon: Icons.monetization_on,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarberEarningsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
