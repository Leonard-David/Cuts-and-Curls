// lib/data/repositories/payment_repository.dart
// Updated with Stripe Connect integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/stripe_helper.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create payment record with Stripe Connect integration
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
              final data = doc.data();
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
              final data = doc.data();
              return PaymentModel.fromMap(data);
            })
            .toList());
  }

  Stream<PaymentModel?> getPaymentByAppointmentStream(String appointmentId) {
    return _firestore
        .collection('payments')
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return PaymentModel.fromMap(snapshot.docs.first.data());
          }
          return null;
        });
  }

  // Update payment status with Stripe webhook integration
  Future<void> updatePaymentStatus(
      String paymentId, String status, String? transactionId) async {
    try {
      final updateData = <String, dynamic>{
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

  // Process payment with Stripe Connect
  Future<Map<String, dynamic>> processStripePayment({
    required String paymentId,
    required double amount,
    required String barberStripeAccountId,
    required String clientEmail,
    required String currency,
  }) async {
    try {
      // Create payment intent with Stripe Connect
      final paymentIntent = await StripeHelper.createPaymentIntent(
        amount: amount,
        currency: currency,
        stripeAccountId: barberStripeAccountId,
        customerEmail: clientEmail,
      );

      return {
        'success': true,
        'paymentIntentId': paymentIntent['id'],
        'clientSecret': paymentIntent['client_secret'],
        'message': 'Payment intent created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Stripe payment failed: $e',
      };
    }
  }

  // Confirm Stripe payment
  Future<Map<String, dynamic>> confirmStripePayment({
    required String paymentIntentId,
    required String clientSecret,
  }) async {
    try {
      final result = await StripeHelper.confirmPayment(
        paymentIntentId: paymentIntentId,
        clientSecret: clientSecret,
      );

      if (result['success'] == true) {
        return {
          'success': true,
          'transactionId': paymentIntentId,
          'message': 'Payment completed successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment confirmation failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment confirmation error: $e',
      };
    }
  }

  // Process mobile money payment (simulated)
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required String paymentId,
    required double amount,
    required String phoneNumber,
    required String provider,
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

  // Get barber's Stripe account status
  Future<Map<String, dynamic>> getBarberStripeStatus(String barberId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(barberId).get();
      final userData = userDoc.data();
      
      if (userData == null || userData['stripeAccountId'] == null) {
        return {
          'connected': false,
          'verified': false,
          'message': 'Stripe account not set up',
        };
      }

      final stripeAccountId = userData['stripeAccountId'];
      final isVerified = await StripeHelper.isAccountVerified(stripeAccountId);

      return {
        'connected': true,
        'verified': isVerified,
        'stripeAccountId': stripeAccountId,
        'message': isVerified ? 'Account verified' : 'Account pending verification',
      };
    } catch (e) {
      return {
        'connected': false,
        'verified': false,
        'error': 'Failed to check Stripe status: $e',
      };
    }
  }
}