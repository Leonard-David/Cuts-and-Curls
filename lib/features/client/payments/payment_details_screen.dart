import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/payment_model.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final PaymentModel payment;

  const PaymentDetailsScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payment Status Card
            _buildStatusCard(context),
            const SizedBox(height: 16),
            // Payment Details Card
            _buildDetailsCard(context),
            const SizedBox(height: 16),
            // Actions Card
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(payment.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(payment.status),
                size: 32,
                color: _getStatusColor(payment.status),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              payment.status.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(payment.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(payment.status),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                'Amount', 'N\$${payment.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Payment Method', payment.paymentMethod),
            _buildDetailRow('Created',
                DateFormat('MMM d, yyyy • HH:mm').format(payment.createdAt)),
            if (payment.completedAt != null)
              _buildDetailRow(
                  'Completed',
                  DateFormat('MMM d, yyyy • HH:mm')
                      .format(payment.completedAt!)),
            if (payment.transactionId != null)
              _buildDetailRow('Transaction ID', payment.transactionId!),
            _buildDetailRow('Appointment ID', payment.appointmentId),
            _buildDetailRow('Barber ID', payment.barberId),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (payment.status == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _payNow(context),
                  child: const Text('Pay Now'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelPayment(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Cancel Payment'),
                ),
              ),
            ],
            if (payment.status == 'failed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _retryPayment(context),
                  child: const Text('Retry Payment'),
                ),
              ),
            ],
            if (payment.status == 'completed') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _downloadReceipt(context),
                  child: const Text('Download Receipt'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _contactSupport(context),
                child: const Text('Contact Support'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _payNow(BuildContext context) {
    showCustomSnackBar(
      context,
      'Redirecting to payment gateway...',
      type: SnackBarType.info,
    );
  }

  void _cancelPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmCancelPayment(context);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelPayment(BuildContext context) {
    showCustomSnackBar(
      context,
      'Payment cancelled successfully',
      type: SnackBarType.success,
    );
  }

  void _retryPayment(BuildContext context) {
    showCustomSnackBar(
      context,
      'Retrying payment...',
      type: SnackBarType.info,
    );
  }

  void _downloadReceipt(BuildContext context) {
    showCustomSnackBar(
      context,
      'Downloading receipt...',
      type: SnackBarType.info,
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For payment-related issues, please contact our support team at:\n\n'
          'Email: payments@sheersync.com\n'
          'Phone: +1-555-PAYMENT\n\n'
          'Please have your transaction ID ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.accent;
      case 'failed':
        return AppColors.error;
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

  String _getStatusDescription(String status) {
    switch (status) {
      case 'completed':
        return 'Payment was successfully processed';
      case 'pending':
        return 'Waiting for payment confirmation';
      case 'failed':
        return 'Payment failed to process';
      default:
        return 'Unknown payment status';
    }
  }
}
