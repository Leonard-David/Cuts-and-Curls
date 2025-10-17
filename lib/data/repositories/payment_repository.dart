// lib/data/repositories/payment_repository.dart
// Handles interactions with payments. For creating PaymentIntent we use Cloud Functions
// callable named 'createPaymentIntent' (deploy on server). Payment documents are written
// by the Cloud Function webhook handler for security.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final CollectionReference _paymentsRef = FirebaseFirestore.instance.collection('payments');

  PaymentRepository();

  /// Calls Cloud Function to create a payment intent (Stripe) and returns clientSecret.
  /// `paymentData` should include: amount (in minor units if needed), currency, appointmentId, clientId, barberId
  Future<String> createPaymentIntent(Map<String, dynamic> paymentData) async {
    try {
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call(paymentData);
      final data = result.data as Map<String, dynamic>;
      // Cloud Function should return { clientSecret: '...', paymentIntentId: '...' }
      final clientSecret = data['clientSecret'] as String?;
      if (clientSecret == null) throw FirebaseFunctionsException(code: 'NO_CLIENT_SECRET', message: 'No clientSecret returned');
      return clientSecret;
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create payment intent: ${e.toString()}');
    }
  }

  /// Get payment document by id (read-only).
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _paymentsRef.doc(paymentId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Stream payments for a barber (useful for earnings dashboard).
  Stream<List<PaymentModel>> streamPaymentsForBarber(String barberId) {
    final q = _paymentsRef.where('barberId', isEqualTo: barberId).orderBy('createdAt', descending: true);
    return q.snapshots().map((snap) => snap.docs.map((d) => PaymentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }
}
