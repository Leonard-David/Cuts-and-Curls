// lib/data/models/payment_model.dart
// Model representing a payment record.
// Maps to /payments/{paymentId}

class PaymentModel {
  final String id;
  final String appointmentId;
  final String clientId;
  final String barberId;
  final double amount;
  final String currency;
  final String method; // e.g. stripe, payfast, mobile_money
  final String status; // pending | succeeded | failed | refunded
  final Map<String, dynamic>? metadata;
  final int createdAtEpoch;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.barberId,
    required this.amount,
    this.currency = 'NAD',
    this.method = 'stripe',
    required this.status,
    this.metadata,
    required this.createdAtEpoch,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      clientId: map['clientId'] ?? '',
      barberId: map['barberId'] ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      currency: map['currency'] ?? 'NAD',
      method: map['method'] ?? 'stripe',
      status: map['status'] ?? 'pending',
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
      createdAtEpoch: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toMap() => {
        'appointmentId': appointmentId,
        'clientId': clientId,
        'barberId': barberId,
        'amount': amount,
        'currency': currency,
        'method': method,
        'status': status,
        'metadata': metadata,
        'createdAt': createdAtEpoch,
      }..removeWhere((k, v) => v == null);
}
