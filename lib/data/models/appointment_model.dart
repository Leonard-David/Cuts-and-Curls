// lib/data/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;               // Firestore doc ID
  final String clientId;         // UID of the client
  final String barberId;         // UID of the barber
  final String serviceId;        // Optional: references a service
  final String serviceName;
  final double price;
  final DateTime appointmentDate;
  final String status;           // pending, confirmed, completed, canceled
  final String? notes;           // optional client notes
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.barberId,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.appointmentDate,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  // Convert from Firestore map
  factory AppointmentModel.fromMap(Map<String, dynamic> data, String docId) {
    return AppointmentModel(
      id: docId,
      clientId: data['clientId'] ?? '',
      barberId: data['barberId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'barberId': barberId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? barberId,
    String? serviceId,
    String? serviceName,
    double? price,
    DateTime? appointmentDate,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      barberId: barberId ?? this.barberId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
