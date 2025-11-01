import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/repositories/payment_repository.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  String _selectedFilter = 'all'; // all, completed, pending, failed

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clientId = authProvider.user?.id;

    if (clientId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login again')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 16),
          // Payments List
          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              stream: _paymentRepository.getClientPayments(clientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final payments = _filterPayments(snapshot.data!);
                
                if (payments.isEmpty) {
                  return _buildEmptyFilterState();
                }

                return _buildPaymentsList(payments);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = {
      'all': 'All Payments',
      'completed': 'Completed',
      'pending': 'Pending',
      'failed': 'Failed',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(entry.value),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = entry.key;
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Your payment history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${_getFilterLabel()} payments',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try selecting a different filter',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<PaymentModel> payments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentItem(payment);
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
            color: _getStatusColor(payment.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStatusIcon(payment.status),
            color: _getStatusColor(payment.status),
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
              'Appointment: ${payment.appointmentId.substring(0, 8)}...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(payment.createdAt),
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
                color: _getStatusColor(payment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payment.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(payment.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _showPaymentDetails(payment);
        },
      ),
    );
  }

  void _showPaymentDetails(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Payment ID:', payment.id.substring(0, 12)),
            _buildDetailItem('Amount:', 'N\$${payment.amount.toStringAsFixed(2)}'),
            _buildDetailItem('Status:', payment.status.toUpperCase()),
            _buildDetailItem('Method:', payment.paymentMethod),
            if (payment.transactionId != null)
              _buildDetailItem('Transaction ID:', payment.transactionId!),
            _buildDetailItem('Date:', DateFormat('MMM d, yyyy, h:mm a').format(payment.createdAt)),
            if (payment.completedAt != null)
              _buildDetailItem('Completed:', DateFormat('MMM d, yyyy, h:mm a').format(payment.completedAt!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<PaymentModel> _filterPayments(List<PaymentModel> payments) {
    switch (_selectedFilter) {
      case 'completed':
        return payments.where((payment) => payment.status == 'completed').toList();
      case 'pending':
        return payments.where((payment) => payment.status == 'pending').toList();
      case 'failed':
        return payments.where((payment) => payment.status == 'failed').toList();
      case 'all':
      default:
        return payments;
    }
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'completed': return 'completed';
      case 'pending': return 'pending';
      case 'failed': return 'failed';
      default: return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}