// lib/features/barber/barber_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/user_provider.dart';
import 'package:intl/intl.dart';

class BarberDashboardPage extends ConsumerWidget {
  const BarberDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSnap = ref.watch(currentUserDocProvider);
    // extract uid to fetch stats
    final uid = userSnap.asData?.value?['uid'];

    return userSnap.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('No profile found')));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: user['profileImage'] != null
                      ? NetworkImage(user['profileImage'])
                      : null,
                  child: user['profileImage'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}', style: const TextStyle(fontSize: 16)),
                    Text((user['role'] ?? '').toString().toUpperCase(), style: const TextStyle(fontSize: 12))
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // rebuild providers by invalidating them if desired
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Welcome + quick stats placeholder
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Welcome back, ${user['firstName'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                // Stats row (uses a FutureProvider)
                if (uid != null)
                  Consumer(builder: (_, ref2, __) {
                    final statsAsync = ref2.watch(barberStatsProvider(uid));
                    return statsAsync.when(
                      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                      error: (e, st) => Text('Stats error: $e'),
                      data: (stats) {
                        final formatter = NumberFormat.currency(symbol: '\$');
                        return Row(
                          children: [
                            _statCard('Total', stats['total'] as int, AppColors.primary),
                            const SizedBox(width: 8),
                            _statCard('Pending', stats['pending'] as int, Colors.orange),
                            const SizedBox(width: 8),
                            _statCard('Completed', stats['completed'] as int, Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Earnings', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Text(formatter.format(stats['earnings'] as double), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),

                const SizedBox(height: 20),

                // Recent appointments list (snapshot stream)
                if (uid != null)
                  Expanded(
                    child: Consumer(builder: (_, ref2, __) {
                      final apptSnap = ref2.watch(barberAppointmentsStreamProvider(uid));
                      return apptSnap.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Appointments error: $e')),
                        data: (snap) {
                          if (snap.docs.isEmpty) return const Center(child: Text('No recent appointments'));
                          return ListView.separated(
                            itemCount: snap.docs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final doc = snap.docs[i].data();
                              final when = (doc['scheduledAt'] as Timestamp?)?.toDate();
                              return ListTile(
                                leading: CircleAvatar(child: Text((doc['clientName'] ?? 'C').toString()[0])),
                                title: Text(doc['service'] ?? 'Service'),
                                subtitle: Text('Client: ${doc['clientName'] ?? '—'} • ${when != null ? DateFormat.yMMMd().add_jm().format(when) : ''}'),
                                trailing: Text(doc['status'] ?? ''),
                                onTap: () {
                                  // navigate to appointment detail
                                  // context.go('/appointment/${snap.docs[i].id}');
                                },
                              );
                            },
                          );
                        },
                      );
                    }),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text('$value', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}
