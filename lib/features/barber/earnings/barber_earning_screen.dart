import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/payment_model.dart';

class BarberEarningsScreen extends StatefulWidget {
  const BarberEarningsScreen({super.key});

  @override
  State<BarberEarningsScreen> createState() => _BarberEarningsScreenState();
}

class _BarberEarningsScreenState extends State<BarberEarningsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  double totalEarnings = 0.0;
  bool _loading = true;
  List<PaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('barberId', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'success')
          .orderBy('createdAt', descending: true)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();

      totalEarnings =
          payments.fold(0.0, (summ, p) => summ + (p.amount));

      setState(() {
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Earnings load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load earnings data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a barber to view earnings.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEarnings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 💰 Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Earnings',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${totalEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🧾 Payment History
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Payments',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _payments.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No payment records yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _payments.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final payment = _payments[index];
                              final date = payment.createdAt;
                              final formattedDate =
                                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.green..withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.attach_money,
                                      color: Colors.green,
                                    ),
                                  ),
                                  title: Text(
                                    '\$${payment.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text('Date: $formattedDate'),
                                  trailing: Text(
                                    payment.currency.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
