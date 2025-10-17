// lib/data/repositories/booking_repository.dart
// Responsible for appointment creation, conflict checking, status updates, and queries.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class BookingRepository {
  final CollectionReference _appointmentsRef = FirebaseFirestore.instance.collection('appointments');

  BookingRepository();

  /// Create an appointment with conflict-checking transaction.
  /// Throws an exception if a conflict (overlap) is found.
  Future<String> createAppointment(AppointmentModel appointment) async {
    // Use a transaction to check overlapping appointments for the barber.
    return FirebaseFirestore.instance.runTransaction<String>((tx) async {
      // Query existing appointments for the barber in the proposed time range that are not cancelled/rejected
      final q = await _appointmentsRef
          .where('barberId', isEqualTo: appointment.barberId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      // Convert docs to AppointmentModel and check overlap client-side
      for (final doc in q.docs) {
        final existing = AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        // Overlap check: startA < endB && startB < endA
        if (appointment.startAt.isBefore(existing.endAt) && existing.startAt.isBefore(appointment.endAt)) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Selected time slot conflicts with an existing booking',
          );
        }
      }

      // If no conflicts, create appointment doc
      final newDocRef = _appointmentsRef.doc();
      tx.set(newDocRef, appointment.toMap());
      return newDocRef.id;
    // ignore: body_might_complete_normally_catch_error
    }).catchError((e) {
      // propagate meaningful errors
      if (e is FirebaseException) {
        throw Exception('Failed to create appointment: ${e.toString()}');
      }
    });
  }

  /// Stream appointments for a barber. Filter by status optionally.
  Stream<List<AppointmentModel>> streamAppointmentsForBarber(String barberId, {List<String>? statuses}) {
    Query q = _appointmentsRef.where('barberId', isEqualTo: barberId);
    if (statuses != null && statuses.isNotEmpty) q = q.where('status', whereIn: statuses);
    q = q.orderBy('startAt', descending: false);
    return q.snapshots().map((snap) {
      return snap.docs.map((d) => AppointmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    });
  }

  /// Stream appointments for a client.
  Stream<List<AppointmentModel>> streamAppointmentsForClient(String clientId, {List<String>? statuses}) {
    Query q = _appointmentsRef.where('clientId', isEqualTo: clientId);
    if (statuses != null && statuses.isNotEmpty) q = q.where('status', whereIn: statuses);
    q = q.orderBy('startAt', descending: false);
    return q.snapshots().map((snap) {
      return snap.docs.map((d) => AppointmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    });
  }

  /// Update appointment status (accept/reject/cancel/complete).
  Future<void> updateStatus(String appointmentId, String newStatus) async {
    await _appointmentsRef.doc(appointmentId).update({'status': newStatus});
  }

  /// Cancel an appointment (mark as cancelled). Optionally add cancellation reason.
  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    final updates = {'status': 'cancelled'};
    if (reason != null) updates['cancelReason'] = reason;
    await _appointmentsRef.doc(appointmentId).update(updates);
  }

  /// Fetch single appointment by id
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    final doc = await _appointmentsRef.doc(appointmentId).get();
    if (!doc.exists) return null;
    return AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
