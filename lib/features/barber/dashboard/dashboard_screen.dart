// lib/features/barber/dashboard/dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class BarberDashboardScreen extends StatefulWidget {
  const BarberDashboardScreen({super.key});
  @override
  State<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends State<BarberDashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Scaffold(
        body: Center(child: Text('Please log in as a barber.')),
      );

    // Stream appointments for this barber
    final appointmentsStream = _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: user!.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: appointmentsStream,
          builder: (context, snap) {
            if (snap.hasError)
              return const Center(child: Text('Failed to load'));
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());

            final docs = snap.data!.docs;
            final total = docs.length;
            final completed = docs
                .where((d) => d['status'] == 'completed')
                .length;
            final pending = docs.where((d) => d['status'] == 'pending').length;
            final totalEarnings = docs
                .where((d) => d['status'] == 'completed')
                .fold<double>(
                  0.0,
                  (sum, d) => sum + (d['price'] as num).toDouble(),
                );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile row like mock
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: const AssetImage(
                          'lib/assets/images/avatar_placeholder.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user!.displayName ?? 'Barber Name',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Barber',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications),
                      ),
                      PopupMenuButton<int>(
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 1,
                            child: Text('Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Overview tabs (Overview, Gallery, Services)
                  Row(
                    children: [
                      _tabChip('Overview', true),
                      const SizedBox(width: 8),
                      _tabChip('Gallery', false),
                      const SizedBox(width: 8),
                      _tabChip('Services', false),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary cards (Total Clients, This week, Total income)
                  Row(
                    children: [
                      Expanded(
                        child: _statCard('Total Clients', '0'),
                      ), // placeholder - compute later
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('This week', 'N\$0.00')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          'Total Income',
                          '\$${totalEarnings.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Booking status card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.event),
                                  Text(
                                    '$total\nTotal\nAppointments',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  Text(
                                    '$completed\nCompleted',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.orange,
                                  ),
                                  Text(
                                    '$pending\nPending',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Today's appointments preview (first 2)
                  const Text(
                    'Today\'s Appointments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...docs.take(3).map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final clientName = data['clientName'] ?? 'Client';
                    final date = (data['time'] is Timestamp)
                        ? (data['time'] as Timestamp).toDate()
                        : DateTime.now();
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${data['service'] ?? 'Service'} with $clientName',
                        ),
                        subtitle: Text('${date.toLocal()}'),
                        trailing: Text(data['status'] ?? ''),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Reviews area placeholder
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text('Average: 5.0'),
                          const SizedBox(height: 8),
                          const Text(
                            'Latest review: Great service!',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tabChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
