import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/repositories/payment_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import '../../../data/models/appointment_model.dart';

class PaymentsScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final PaymentModel? existingPayment;

  const PaymentsScreen({
    super.key,
    required this.appointment,
    this.existingPayment,
  });

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String _selectedPaymentMethod = 'cash'; // cash, card, mobile_money
  bool _isProcessing = false;
  bool _saveCard = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if existing payment
    if (widget.existingPayment != null) {
      _selectedPaymentMethod = widget.existingPayment!.paymentMethod;
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'cash') {
      await _handleCashPayment();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final client = authProvider.user!;

      // Create or get payment record
      final payment = widget.existingPayment ?? PaymentModel(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        appointmentId: widget.appointment.id,
        clientId: client.id,
        barberId: widget.appointment.barberId,
        amount: widget.appointment.price ?? 0.0,
        paymentMethod: _selectedPaymentMethod,
        createdAt: DateTime.now(),
      );

      if (widget.existingPayment == null) {
        await _paymentRepository.createPayment(payment);
      }

      Map<String, dynamic> result;

      if (_selectedPaymentMethod == 'card') {
        // Validate card details
        if (!_validateCardDetails()) {
          throw Exception('Please check your card details');
        }

        result = await _paymentRepository.processPayment(
          paymentId: payment.id,
          amount: payment.amount,
          paymentMethod: _selectedPaymentMethod,
          cardNumber: _cardNumberController.text.replaceAll(' ', ''),
          expiryDate: _expiryController.text,
          cvv: _cvvController.text,
          cardHolder: _cardHolderController.text,
        );
      } else if (_selectedPaymentMethod == 'mobile_money') {
        // Validate phone number
        if (_phoneNumberController.text.isEmpty) {
          throw Exception('Please enter your phone number');
        }

        result = await _paymentRepository.processMobileMoneyPayment(
          paymentId: payment.id,
          amount: payment.amount,
          phoneNumber: _phoneNumberController.text,
          provider: 'mtn', // You can make this selectable
        );
      } else {
        throw Exception('Unsupported payment method');
      }

      if (result['success'] == true) {
        await _paymentRepository.updatePaymentStatus(
          payment.id,
          'completed',
          result['transactionId'],
        );

        if (mounted) {
          showCustomSnackBar(
            context,
            result['message'] ?? 'Payment completed successfully!',
            type: SnackBarType.success,
          );
          Navigator.pop(context);
        }
      } else {
        await _paymentRepository.updatePaymentStatus(
          payment.id,
          'failed',
          null,
        );

        if (mounted) {
          showCustomSnackBar(
            context,
            result['error'] ?? 'Payment failed. Please try again.',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Payment error: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleCashPayment() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final client = authProvider.user!;

      final payment = PaymentModel(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        appointmentId: widget.appointment.id,
        clientId: client.id,
        barberId: widget.appointment.barberId,
        amount: widget.appointment.price ?? 0.0,
        status: 'completed',
        paymentMethod: 'cash',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await _paymentRepository.createPayment(payment);

      if (mounted) {
        showCustomSnackBar(
          context,
          'Cash payment recorded. Please pay at the salon.',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Failed to record payment: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  bool _validateCardDetails() {
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _cardHolderController.text.isEmpty) {
      return false;
    }

    // Basic card number validation (16 digits)
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    if (cardNumber.length != 16) return false;

    // Basic expiry validation (MM/YY)
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_expiryController.text)) return false;

    // Basic CVV validation (3 or 4 digits)
    if (!RegExp(r'^\d{3,4}$').hasMatch(_cvvController.text)) return false;

    return true;
  }

  void _formatCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    final formatted = <String>[];

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.add(' ');
      }
      formatted.add(cleaned[i]);
    }

    _cardNumberController.value = _cardNumberController.value.copyWith(
      text: formatted.join(),
      selection: TextSelection.collapsed(offset: formatted.join().length),
    );
  }

  void _formatExpiry(String value) {
    if (value.length == 2 && !value.contains('/')) {
      _expiryController.text = '$value/';
      _expiryController.selection = TextSelection.collapsed(offset: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isProcessing
          ? _buildProcessingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Summary
                  _buildPaymentSummary(),
                  const SizedBox(height: 24),
                  // Payment Method Selection
                  _buildPaymentMethodSelection(),
                  const SizedBox(height: 24),
                  // Payment Form
                  _buildPaymentForm(),
                  const SizedBox(height: 32),
                  // Pay Button
                  _buildPayButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProcessingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing Payment...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we process your payment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // In the _buildPaymentSummary method:
  Widget _buildPaymentSummary() {
    // If no appointment is provided, show a generic payment form
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service:', style: TextStyle(fontSize: 16)),
                Text(
                  widget.appointment.serviceName ?? 'Hair Service',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Barber:', style: TextStyle(fontSize: 16)),
                Text(
                  widget.appointment.barberName ?? 'Barber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'N\${widget.appointment!.price?.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    const paymentMethods = [
      {'value': 'cash', 'label': 'Cash', 'icon': Icons.money_off},
      {'value': 'card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card},
      {'value': 'mobile_money', 'label': 'Mobile Money', 'icon': Icons.phone_android},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...paymentMethods.map((method) {
          final methodValue = method['value'] as String;
          final methodLabel = method['label'] as String;
          final methodIcon = method['icon'] as IconData;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: _selectedPaymentMethod == methodValue ? 4 : 1,
            color: _selectedPaymentMethod == methodValue 
                ? Colors.blue.shade50 
                : Colors.white,
            child: ListTile(
              leading: Icon(methodIcon, color: Colors.blue),
              title: Text(methodLabel),
              trailing: Radio<String>(
                value: methodValue,
                groupValue: _selectedPaymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = methodValue;
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedPaymentMethod == 'cash') {
      return _buildCashPaymentInfo();
    } else if (_selectedPaymentMethod == 'card') {
      return _buildCardPaymentForm();
    } else if (_selectedPaymentMethod == 'mobile_money') {
      return _buildMobileMoneyForm();
    } else {
      return Container();
    }
  }

  Widget _buildCashPaymentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, color: Colors.blue, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Cash Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please pay the amount of N\$${widget.appointment.price?.toStringAsFixed(2) ?? '0.00'} in cash when you visit the barber.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '📍 Payment Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Bring exact change if possible'),
            const Text('• Payment is due at the time of service'),
            const Text('• Receipt will be provided upon payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Card Number
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              onChanged: _formatCardNumber,
              maxLength: 19, // 16 digits + 3 spaces
            ),
            const SizedBox(height: 16),
            // Expiry and CVV
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _formatExpiry,
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Card Holder Name
            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Card Holder Name',
                hintText: 'John Doe',
              ),
            ),
            const SizedBox(height: 16),
            // Save Card Option
            CheckboxListTile(
              value: _saveCard,
              onChanged: (value) {
                setState(() {
                  _saveCard = value ?? false;
                });
              },
              title: const Text('Save card for future payments'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mobile Money',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Phone Number
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '264 81 234 5678',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // Provider Selection
            const Text(
              'Select Provider:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['MTN', 'Airtel', 'Telecom'].map((provider) {
                return ChoiceChip(
                  label: Text(provider),
                  selected: true, // You can make this selectable
                  onSelected: (selected) {},
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              '📱 Payment Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Enter your mobile money number'),
            const Text('2. Confirm the payment on your phone'),
            const Text('3. Wait for payment confirmation'),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(
              _selectedPaymentMethod == 'cash' 
                  ? 'Confirm Cash Payment' 
                  : 'Pay N\$${widget.appointment.price?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}