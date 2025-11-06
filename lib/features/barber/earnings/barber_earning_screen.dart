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

class _BarberEarningScreenState extends State<BarberEarningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      return _buildErrorState('Please login again');
    }

    return Column(
      children: [
        // --- Tab Bar (Now matches BarberAppointmentsScreen) ---
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(
            height: 48,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'All Time'),
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'This Month'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- Earnings Summary ---
        _buildEarningsSummary(barberId),
        const SizedBox(height: 16),

        // --- Recent Payments List ---
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecentPayments(barberId, 'today'),
              _buildRecentPayments(barberId, 'week'),
              _buildRecentPayments(barberId, 'month'),
              _buildRecentPayments(barberId, 'all'),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------- SUMMARY CARD --------------------

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
        final filteredPayments = _filterPaymentsByTimeRange(
          payments,
          _getCurrentTimeRange(),
        );
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
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
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

  // -------------------- PAYMENT LIST --------------------

  Widget _buildRecentPayments(String barberId, String timeRange) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('barberId', isEqualTo: barberId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data!.docs;
        final filteredPayments = _filterPaymentsByTimeRange(payments, timeRange);

        if (filteredPayments.isEmpty) {
          return _buildEmptyPaymentsState();
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredPayments.length,
            itemBuilder: (context, index) {
              final payment = PaymentModel.fromMap(
                filteredPayments[index].data() as Map<String, dynamic>,
              );
              return _buildPaymentItem(payment);
            },
          ),
        );
      },
    );
  }

  // -------------------- HELPERS --------------------

  String _getCurrentTimeRange() {
    switch (_tabController.index) {
      case 0:
        return 'today';
      case 1:
        return 'week';
      case 2:
        return 'month';
      case 3:
      default:
        return 'all';
    }
  }

  List<QueryDocumentSnapshot> _filterPaymentsByTimeRange(
      List<QueryDocumentSnapshot> payments, String timeRange) {
    final now = DateTime.now();

    switch (timeRange) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return payments.where((doc) {
          final payment =
              PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
          return payment.completedAt != null &&
              payment.completedAt!.isAfter(today);
        }).toList();

      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return payments.where((doc) {
          final payment =
              PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
          return payment.completedAt != null &&
              payment.completedAt!.isAfter(weekAgo);
        }).toList();

      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30)); // safer version
        return payments.where((doc) {
          final payment =
              PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
          return payment.completedAt != null &&
              payment.completedAt!.isAfter(monthAgo);
        }).toList();

      case 'all':
      default:
        return payments;
    }
  }

  Map<String, dynamic> _calculateEarningsStats(
      List<QueryDocumentSnapshot> payments) {
    double totalEarnings = 0.0;
    int completedPayments = payments.length;
    int totalServices = payments.length;

    for (final doc in payments) {
      final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>);
      totalEarnings += payment.amount;
    }

    final averageEarning =
        completedPayments > 0 ? totalEarnings / completedPayments : 0.0;

    return {
      'totalEarnings': totalEarnings,
      'completedPayments': completedPayments,
      'averageEarning': averageEarning,
      'totalServices': totalServices,
    };
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.payment_rounded, color: AppColors.success),
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
            if (payment.completedAt != null)
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'card':
        return 'Credit Card';
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      default:
        return method;
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Payments Yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed payment records will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
