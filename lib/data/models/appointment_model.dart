// lib/data/models/appointment_model.dart
// Model for appointments/bookings.
// Maps to /appointments/{appointmentId}

import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String clientId;
  final String barberId;
  final String serviceId;
  final DateTime startAt;
  final DateTime endAt;
  final String status; // pending|confirmed|rejected|completed|cancelled
  final String? paymentId;
  final String? notes;
  final int createdAtEpoch;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.barberId,
    required this.serviceId,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.paymentId,
    this.notes,
    required this.createdAtEpoch,
  });

  // Firestore stores timestamps as Timestamp type — convert safely here
  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseTimestamp(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    final start = parseTimestamp(map['startAt']);
    final end = parseTimestamp(map['endAt']);

    return AppointmentModel(
      id: id,
      clientId: map['clientId'] ?? '',
      barberId: map['barberId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      startAt: start,
      endAt: end,
      status: map['status'] ?? 'pending',
      paymentId: map['paymentId'] as String?,
      notes: map['notes'] as String?,
      createdAtEpoch: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  // Convert to Firestore-friendly map. Use Timestamps for better compatibility.
  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'barberId': barberId,
        'serviceId': serviceId,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'status': status,
        'paymentId': paymentId,
        'notes': notes,
        'createdAt': createdAtEpoch,
      }..removeWhere((k, v) => v == null);
}
