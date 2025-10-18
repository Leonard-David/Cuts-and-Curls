import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/booking_repository.dart';

class PaymentScreen extends StatefulWidget {
  final String appointmentId;
  final String barberId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.barberId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final user = FirebaseAuth.instance.currentUser;
  bool _processing = false;

  Future<void> _handlePayment() async {
    if (user == null) return;
    setState(() => _processing = true);

    try {
      final clientSecret =
          await _paymentRepo.createPaymentIntent(widget.amount, 'usd');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Cuts & Curls',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Record payment
      final payment = PaymentModel(
        id: '',
        appointmentId: widget.appointmentId,
        clientId: user!.uid,
        barberId: widget.barberId,
        amount: widget.amount,
        currency: 'usd',
        status: 'success',
        createdAt: DateTime.now(),
      );

      await _paymentRepo.savePayment(payment);
      await _bookingRepo.updateAppointmentStatus(widget.appointmentId, 'paid');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              'Pay \$${widget.amount.toStringAsFixed(2)} for your appointment',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            _processing
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _handlePayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Pay Now'),
                  ),
          ],
        ),
      ),
    );
  }
}
