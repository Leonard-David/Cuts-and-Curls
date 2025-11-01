import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create payment record
  Future<void> createPayment(PaymentModel payment) async {
    try {
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .set(payment.toMap());
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  // Get payments for client
  Stream<List<PaymentModel>> getClientPayments(String clientId) {
    return _firestore
        .collection('payments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return PaymentModel.fromMap(data);
            })
            .toList());
  }

  // Get payments for barber
  Stream<List<PaymentModel>> getBarberPayments(String barberId) {
    return _firestore
        .collection('payments')
        .where('barberId', isEqualTo: barberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return PaymentModel.fromMap(data);
            })
            .toList());
  }

  // Update payment status
  Future<void> updatePaymentStatus(
      String paymentId, String status, String? transactionId) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      if (status == 'completed') {
        updateData['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  // Get payment by appointment ID
  Future<PaymentModel?> getPaymentByAppointment(String appointmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return PaymentModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  // Simulate payment processing (for demo purposes)
  Future<Map<String, dynamic>> processPayment({
    required String paymentId,
    required double amount,
    required String paymentMethod,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolder,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate payment processing logic
    final success = cardNumber.endsWith('4242'); // Test card pattern
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';

    if (success) {
      return {
        'success': true,
        'transactionId': transactionId,
        'message': 'Payment processed successfully',
      };
    } else {
      return {
        'success': false,
        'error': 'Payment declined. Please check your card details.',
      };
    }
  }

  // Process mobile money payment (simulated)
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required String paymentId,
    required double amount,
    required String phoneNumber,
    required String provider, // mtn, airtel, etc.
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 3));

    // Simulate mobile money processing
    final success = phoneNumber.isNotEmpty;
    final transactionId = 'mm_${DateTime.now().millisecondsSinceEpoch}';

    if (success) {
      return {
        'success': true,
        'transactionId': transactionId,
        'message': 'Mobile money payment initiated',
      };
    } else {
      return {
        'success': false,
        'error': 'Failed to initiate mobile money payment',
      };
    }
  }
}