import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/utils/firestore_helper.dart';
import '../models/appointment_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new appointment
  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Get appointments for barber using helper
Stream<List<AppointmentModel>> getBarberAppointments(String barberId) {
  return _firestore
      .collection('appointments')
      .where('barberId', isEqualTo: barberId)
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) => FirestoreHelper.convertDocsToModels(
            snapshot.docs,
            AppointmentModel.fromMap,
          ));
}

  // Get appointments for client
  Stream<List<AppointmentModel>> getClientAppointments(String clientId) {
    return _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return AppointmentModel.fromMap(data);
            })
            .toList());
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Get available time slots for barber
  Future<List<DateTime>> getAvailableTimeSlots(
      String barberId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final bookedSlots = querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()).date)
          .toList();

      return _generateTimeSlots(date, bookedSlots);
    } catch (e) {
      throw Exception('Failed to get available slots: $e');
    }
  }

  // Generate available time slots (9 AM to 6 PM, 30-minute intervals)
  List<DateTime> _generateTimeSlots(DateTime date, List<DateTime> bookedSlots) {
    final List<DateTime> slots = [];
    final startTime = DateTime(date.year, date.month, date.day, 9, 0); // 9 AM
    final endTime = DateTime(date.year, date.month, date.day, 18, 0); // 6 PM

    DateTime currentSlot = startTime;
    while (currentSlot.isBefore(endTime)) {
      // Check if slot is not booked
      final isBooked = bookedSlots.any((booked) =>
          booked.hour == currentSlot.hour && booked.minute == currentSlot.minute);

      if (!isBooked) {
        slots.add(currentSlot);
      }

      currentSlot = currentSlot.add(const Duration(minutes: 30));
    }

    return slots;
  }

  // Check if barber has availability for a specific time
  Future<bool> checkBarberAvailability(
      String barberId, DateTime dateTime) async {
    try {
      final startTime = dateTime;
      final endTime = dateTime.add(const Duration(minutes: 30));

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: startTime)
          .where('date', isLessThan: endTime)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }
}