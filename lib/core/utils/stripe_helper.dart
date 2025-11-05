// lib/core/utils/stripe_helper.dart
// Stripe Connect integration helper for secure payment processing

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeHelper {
  static const String _stripeSecretKey = 'sk_test_51SG6nmFIRxOrHETm6td5g6iKcXDZ2D9C2QACzj5uuqmH8lXRhEc5zYFQtck4DtFWu2Zm55IZ2CGjSmFt2rq0M8GY00JxhpDdKL';
  static const String _stripePublishableKey = 'sk_test_51SG6nmFIRxOrHETm6td5g6iKcXDZ2D9C2QACzj5uuqmH8lXRhEc5zYFQtck4DtFWu2Zm55IZ2CGjSmFt2rq0M8GY00JxhpDdKL';

  // Initialize Stripe configuration
  static Future<void> initialize() async {
     try {
      Stripe.publishableKey = _stripePublishableKey;
      Stripe.merchantIdentifier = 'merchant.flutter.stripe';
      
      // Apply settings with timeout
      await Stripe.instance.applySettings().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Stripe initialization timeout');
        },
      );
      
      print('Stripe initialized successfully');
    } catch (e) {
      print('Stripe initialization error: $e');
      rethrow;
    }
  }

  // Create Stripe Connect account for barber
  static Future<Map<String, dynamic>> createConnectAccount({
    required String email,
    required String country,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/accounts'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'type': 'express',
          'country': country,
          'email': email,
          'capabilities[card_payments][requested]': 'true',
          'capabilities[transfers][requested]': 'true',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create Stripe account: ${response.body}');
      }
    } catch (e) {
      throw Exception('Stripe account creation error: $e');
    }
  }

  // Generate account link for barber onboarding
  static Future<Map<String, dynamic>> createAccountLink({
    required String accountId,
    required String refreshUrl,
    required String returnUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/account_links'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'account': accountId,
          'refresh_url': refreshUrl,
          'return_url': returnUrl,
          'type': 'account_onboarding',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create account link: ${response.body}');
      }
    } catch (e) {
      throw Exception('Account link creation error: $e');
    }
  }

  // Create payment intent with Stripe Connect
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String stripeAccountId,
    required String customerEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Stripe-Account': stripeAccountId,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toStringAsFixed(0), // Convert to cents
          'currency': currency,
          'payment_method_types[]': 'card',
          'receipt_email': customerEmail,
          'application_fee_amount': (amount * 0.10 * 100).toStringAsFixed(0), // 10% platform fee
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment intent creation error: $e');
    }
  }

  // Confirm payment with card details
  static Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String clientSecret,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SheerSync',
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Retrieve payment intent to confirm status
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(clientSecret);

      return {
        'success': paymentIntent.status == PaymentIntentsStatus.Succeeded,
        'paymentIntent': paymentIntent.toJson(),
      };
    } catch (e) {
      throw Exception('Payment confirmation error: $e');
    }
  }

  // Transfer funds to connected account
  static Future<Map<String, dynamic>> transferToConnectedAccount({
    required String connectedAccountId,
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/transfers'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toStringAsFixed(0),
          'currency': currency,
          'destination': connectedAccountId,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to transfer funds: ${response.body}');
      }
    } catch (e) {
      throw Exception('Transfer error: $e');
    }
  }

  // Check if Stripe account is verified
  static Future<bool> isAccountVerified(String accountId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/accounts/$accountId'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
        },
      );

      if (response.statusCode == 200) {
        final account = json.decode(response.body);
        return account['charges_enabled'] == true && account['payouts_enabled'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}