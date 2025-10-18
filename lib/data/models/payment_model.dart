import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String appointmentId;
  final String clientId;
  final String barberId;
  final double amount;
  final String currency;
  final String status; // success / failed / pending
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.barberId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> data, String docId) {
    return PaymentModel(
      id: docId,
      appointmentId: data['appointmentId'] ?? '',
      clientId: data['clientId'] ?? '',
      barberId: data['barberId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'usd',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'clientId': clientId,
      'barberId': barberId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
