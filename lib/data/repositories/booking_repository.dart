// lib/data/repositories/booking_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'appointments';

  /// Create a new booking
  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      await _firestore.collection(collectionPath).add(appointment.toMap());
    } catch (e, st) {
      // Handle Firebase write errors
      debugPrint('Error creating appointment: $e\n$st');
      rethrow;
    }
  }

  /// Update an appointment (e.g., confirm, complete, cancel)
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _firestore.collection(collectionPath).doc(appointmentId).update({
        'status': newStatus,
      });
    } catch (e, st) {
      debugPrint('Error updating appointment status: $e\n$st');
      rethrow;
    }
  }

  /// Fetch appointments for a specific client
  Stream<List<AppointmentModel>> getClientAppointments(String clientId) {
    return _firestore
        .collection(collectionPath)
        .where('clientId', isEqualTo: clientId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppointmentModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Fetch appointments for a specific barber
  Stream<List<AppointmentModel>> getBarberAppointments(String barberId) {
    return _firestore
        .collection(collectionPath)
        .where('barberId', isEqualTo: barberId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppointmentModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Delete an appointment (optional)
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection(collectionPath).doc(appointmentId).delete();
    } catch (e, st) {
      debugPrint('Error deleting appointment: $e\n$st');
      rethrow;
    }
  }

  /// Get single appointment details
  Future<AppointmentModel?> getAppointmentById(String id) async {
    try {
      final doc = await _firestore.collection(collectionPath).doc(id).get();
      if (doc.exists) {
        return AppointmentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e, st) {
      debugPrint('Error getting appointment by ID: $e\n$st');
      rethrow;
    }
  }
}
