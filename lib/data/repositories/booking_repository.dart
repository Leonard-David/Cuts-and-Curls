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
      // Schedule reminder if enabled
      if (appointment.hasReminder && appointment.reminderMinutes != null) {
        await _scheduleAppointmentReminder(appointment);
      }
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }
  // Schedule reminder notification
  Future<void> _scheduleAppointmentReminder(AppointmentModel appointment) async {
    final reminderTime = appointment.date.subtract(
      Duration(minutes: appointment.reminderMinutes!),
    );
    
    // local notifications for reminders
    // You can integrate with your notification service
    print('Reminder scheduled for ${reminderTime} for appointment ${appointment.id}');
  }

   // Get appointments with real-time updates and filtering
  Stream<List<AppointmentModel>> getBarberAppointments(String barberId, {String? statusFilter}) {
    Query query = _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .orderBy('date', descending: false);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) => 
        FirestoreHelper.convertDocsToModels(snapshot.docs, AppointmentModel.fromMap));
  }

  // Get appointment requests (pending appointments)
  Stream<List<AppointmentModel>> getAppointmentRequests(String barberId) {
    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            FirestoreHelper.convertDocsToModels(snapshot.docs, AppointmentModel.fromMap));
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

  // Get real-time appointment by ID
  Stream<AppointmentModel?> getAppointmentByIdStream(String appointmentId) {
    return _firestore
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() ?? {};
            return AppointmentModel.fromMap(data);
          }
          return null;
        });
  }

  // Get appointments with real-time status updates
  Stream<List<AppointmentModel>> getAppointmentsWithStatus(
    String userId, 
    String userType, 
    List<String> statuses
  ) {
    final field = userType == 'client' ? 'clientId' : 'barberId';
    
    return _firestore
        .collection('appointments')
        .where(field, isEqualTo: userId)
        .where('status', whereIn: statuses)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => FirestoreHelper.convertDocsToModels(
              snapshot.docs,
              AppointmentModel.fromMap,
            ));
  }

  // Check if barber has real-time availability
  Stream<bool> checkBarberAvailabilityStream(String barberId, DateTime dateTime) {
    final startTime = dateTime;
    final endTime = dateTime.add(const Duration(minutes: 30));

    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: startTime)
        .where('date', isLessThan: endTime)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty);
  }
  
  // Update appointment status with notification
  Future<void> updateAppointmentStatus(
    String appointmentId, 
    String status, {
    String? reason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (reason != null) {
        updateData['cancellationReason'] = reason;
      }

      await _firestore.collection('appointments').doc(appointmentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  // Set appointment reminder
  Future<void> setAppointmentReminder({
    required String appointmentId,
    required bool hasReminder,
    required int reminderMinutes,
    String? reminderNote,
  }) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'hasReminder': hasReminder,
        'reminderMinutes': reminderMinutes,
        'reminderNote': reminderNote,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to set reminder: $e');
    }
  }

  // Get today's appointments
  Stream<List<AppointmentModel>> getTodaysAppointments(String barberId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .where('status', whereIn: ['confirmed', 'pending'])
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => 
            FirestoreHelper.convertDocsToModels(snapshot.docs, AppointmentModel.fromMap));
  }

  // Get upcoming appointments (next 7 days)
  Stream<List<AppointmentModel>> getUpcomingAppointments(String barberId) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThan: now)
        .where('date', isLessThan: nextWeek)
        .where('status', whereIn: ['confirmed', 'pending'])
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => 
            FirestoreHelper.convertDocsToModels(snapshot.docs, AppointmentModel.fromMap));
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