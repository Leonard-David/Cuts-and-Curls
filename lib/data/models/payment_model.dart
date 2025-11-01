import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class PaymentModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String appointmentId;
  
  @HiveField(2)
  final String clientId;
  
  @HiveField(3)
  final String barberId;
  
  @HiveField(4)
  final double amount;
  
  @HiveField(5)
  final String status;
  
  @HiveField(6)
  final String paymentMethod;
  
  @HiveField(7)
  final String? transactionId;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime? completedAt;
  
  @HiveField(10)
  final String? failureReason;


  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.barberId,
    required this.amount,
    this.status = 'pending',
    this.paymentMethod = 'cash',
    this.transactionId,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'clientId': clientId,
      'barberId': barberId,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'failureReason': failureReason,
    };
  }

  // Create model from Firestore data
  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      appointmentId: map['appointmentId'],
      clientId: map['clientId'],
      barberId: map['barberId'],
      amount: map['amount'].toDouble(),
      status: map['status'],
      paymentMethod: map['paymentMethod'],
      transactionId: map['transactionId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      failureReason: map['failureReason'],
    );
  }

  // Create copy with method for updates
  PaymentModel copyWith({
    String? status,
    String? transactionId,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return PaymentModel(
      id: id,
      appointmentId: appointmentId,
      clientId: clientId,
      barberId: barberId,
      amount: amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}