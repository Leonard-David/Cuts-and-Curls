import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/repositories/payment_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class BarberEarningScreen extends StatefulWidget {
  const BarberEarningScreen({super.key});

  @override
  State<BarberEarningScreen> createState() => _BarberEarningScreenState();
}

class _BarberEarningScreenState extends State<BarberEarningScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  String _selectedPeriod = 'week'; // week, month, year

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      return const Center(child: Text('Please login again'));
    }

    return Scaffold(
      body: StreamBuilder<List<PaymentModel>>(
        stream: _paymentRepository.getBarberPayments(barberId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final payments = snapshot.data!;
          final filteredPayments = _filterPaymentsByPeriod(payments);
          final earningsData = _calculateEarnings(filteredPayments);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                // Earnings Overview
                _buildEarningsOverview(earningsData),
                const SizedBox(height: 24),
                // Recent Transactions
                _buildRecentTransactions(filteredPayments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Earnings Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your earnings will appear here once clients start paying',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = {
      'week': 'This Week',
      'month': 'This Month',
      'year': 'This Year',
      'all': 'All Time',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: periods.entries.map((entry) {
                  final isSelected = _selectedPeriod == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = entry.key;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsOverview(Map<String, dynamic> earningsData) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildEarningCard(
          'Total Earnings',
          'N\$${earningsData['totalEarnings'].toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildEarningCard(
          'Completed Payments',
          earningsData['completedCount'].toString(),
          Icons.check_circle,
          Colors.blue,
        ),
        _buildEarningCard(
          'Pending Payments',
          earningsData['pendingCount'].toString(),
          Icons.pending,
          Colors.orange,
        ),
        _buildEarningCard(
          'Average per Service',
          'N\$${earningsData['averageEarning'].toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildEarningCard(String title, String value, IconData icon, Color color) {
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
                fontSize: 18,
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

  Widget _buildRecentTransactions(List<PaymentModel> payments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...payments.take(10).map((payment) {
              return _buildTransactionItem(payment);
            }).toList(),
            if (payments.length > 10)
              TextButton(
                onPressed: () {
                  // Show all transactions
                },
                child: const Text('View All Transactions'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(PaymentModel payment) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getPaymentStatusIcon(payment.status),
          color: _getPaymentStatusColor(payment.status),
        ),
      ),
      title: Text(
        'Payment #${payment.id.substring(0, 8)}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        DateFormat('MMM d, yyyy • h:mm a').format(payment.createdAt),
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
              color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              payment.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: _getPaymentStatusColor(payment.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PaymentModel> _filterPaymentsByPeriod(List<PaymentModel> payments) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        return payments;
    }

    return payments.where((payment) {
      return payment.createdAt.isAfter(startDate);
    }).toList();
  }

  Map<String, dynamic> _calculateEarnings(List<PaymentModel> payments) {
    final completedPayments = payments.where((p) => p.status == 'completed').toList();
    final pendingPayments = payments.where((p) => p.status == 'pending').toList();
    
    final totalEarnings = completedPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    final averageEarning = completedPayments.isNotEmpty 
        ? totalEarnings / completedPayments.length 
        : 0.0;

    return {
      'totalEarnings': totalEarnings,
      'completedCount': completedPayments.length,
      'pendingCount': pendingPayments.length,
      'averageEarning': averageEarning,
    };
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.help;
    }
  }
}