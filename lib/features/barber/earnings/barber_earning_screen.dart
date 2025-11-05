// lib/features/barber/earnings/barber_earning_screen.dart
// Updated with Stripe Connect earnings tracking

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class BarberEarningScreen extends StatefulWidget {
  const BarberEarningScreen({super.key});

  @override
  State<BarberEarningScreen> createState() => _BarberEarningScreenState();
}

class _BarberEarningScreenState extends State<BarberEarningScreen> {
  String _selectedTimeRange = 'today'; // today, week, month, all

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      return _buildErrorState('Please login again');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Time Range Filter
          _buildTimeRangeFilter(),
          const SizedBox(height: 16),
          // Earnings Summary
          _buildEarningsSummary(barberId),
          const SizedBox(height: 16),
          // Recent Payments
          Expanded(
            child: _buildRecentPayments(barberId),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeFilter() {
    const timeRanges = {
      'today': 'Today',
      'week': 'This Week',
      'month': 'This Month',
      'all': 'All Time',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: timeRanges.entries.map((entry) {
            final isSelected = _selectedTimeRange == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(entry.value),
                onSelected: (selected) {
                  setState(() {
                    _selectedTimeRange = entry.key;
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(String barberId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('barberId', isEqualTo: barberId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingSummary();
        }

        final payments = snapshot.data!.docs;
        final filteredPayments = _filterPaymentsByTimeRange(payments);
        final stats = _calculateEarningsStats(filteredPayments);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.accent.withOpacity(0.05),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Total Earnings
              Text(
                'N\$${stats['totalEarnings'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Earnings',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Completed',
                    stats['completedPayments'].toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                  _buildStatItem(
                    'Average',
                    'N\$${stats['averageEarning'].toStringAsFixed(2)}',
                    Icons.trending_up,
                    AppColors.primary,
                  ),
                  _buildStatItem(
                    'Services',
                    stats['totalServices'].toString(),
                    Icons.work,
                    AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentPayments(String barberId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('barberId', isEqualTo: barberId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data!.docs;
        
        if (payments.isEmpty) {
          return _buildEmptyPaymentsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = PaymentModel.fromMap(
                payments[index].data() as Map<String, dynamic>);
            return _buildPaymentItem(payment);
          },
        );
      },
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.payment_rounded,
            color: AppColors.success,
          ),
        ),
        title: Text(
          'Payment #${payment.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Via ${_formatPaymentMethod(payment.paymentMethod)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(payment.completedAt!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'N\$${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PAID',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Helper methods for filtering, calculations, etc.
  List<QueryDocumentSnapshot> _filterPaymentsByTimeRange(List<QueryDocumentSnapshot> payments) {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return payments.where((doc) {
          final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
          return payment.completedAt!.isAfter(today);
        }).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return payments.where((doc) {
          final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
          return payment.completedAt!.isAfter(weekAgo);
        }).toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return payments.where((doc) {
          final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
          return payment.completedAt!.isAfter(monthAgo);
        }).toList();
      case 'all':
      default:
        return payments;
    }
  }

  Map<String, dynamic> _calculateEarningsStats(List<QueryDocumentSnapshot> payments) {
    double totalEarnings = 0.0;
    int completedPayments = payments.length;
    int totalServices = payments.length;

    for (final doc in payments) {
      final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
      totalEarnings += payment.amount;
    }

    final averageEarning = completedPayments > 0 ? totalEarnings / completedPayments : 0.0;

    return {
      'totalEarnings': totalEarnings,
      'completedPayments': completedPayments,
      'averageEarning': averageEarning,
      'totalServices': totalServices,
    };
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'card': return 'Credit Card';
      case 'mobile_money': return 'Mobile Money';
      case 'cash': return 'Cash';
      default: return method;
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyPaymentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Payments Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed payment records will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Earnings',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}