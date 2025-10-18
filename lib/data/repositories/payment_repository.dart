import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HttpsCallable _createPaymentIntent =
      FirebaseFunctions.instance.httpsCallable('createPaymentIntent');

  /// Create Stripe Payment Intent via Cloud Function
  Future<String> createPaymentIntent(double amount, String currency) async {
    final result = await _createPaymentIntent.call({
      'amount': (amount * 100).toInt(), // convert to cents
      'currency': currency,
    });
    return result.data['clientSecret'];
  }

  /// Save payment record to Firestore
  Future<void> savePayment(PaymentModel payment) async {
    await _firestore.collection('payments').add(payment.toMap());
  }
}
