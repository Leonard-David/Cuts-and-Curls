// lib/features/barber/appointments/barber_appointments_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/booking_repository.dart';

class BarberAppointmentsScreen extends StatefulWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  State<BarberAppointmentsScreen> createState() => _BarberAppointmentsScreenState();
}

class _BarberAppointmentsScreenState extends State<BarberAppointmentsScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _bookingRepo.updateAppointmentStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as $status.')),
      );
    } catch (e) {
      debugPrint('Update status error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a barber to view appointments.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('My Appointments'),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _bookingRepo.getBarberAppointments(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No appointments yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final appointments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final date =
                  '${appt.appointmentDate.day}/${appt.appointmentDate.month}/${appt.appointmentDate.year}';
              final time =
                  '${appt.appointmentDate.hour.toString().padLeft(2, '0')}:${appt.appointmentDate.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Client ID: ${appt.clientId}'),
                      Text('Date: $date  at $time'),
                      Text('Price: \$${appt.price}'),
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${appt.status.toUpperCase()}',
                        style: TextStyle(
                          color: _statusColor(appt.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (appt.notes != null && appt.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Notes: ${appt.notes}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ACTION BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (appt.status == 'pending') ...[
                            _buildActionButton(
                              label: 'Confirm',
                              color: Colors.green,
                              onPressed: () => _updateStatus(appt.id, 'confirmed'),
                            ),
                            const SizedBox(width: 10),
                            _buildActionButton(
                              label: 'Cancel',
                              color: Colors.red,
                              onPressed: () => _updateStatus(appt.id, 'cancelled'),
                            ),
                          ] else if (appt.status == 'confirmed') ...[
                            _buildActionButton(
                              label: 'Mark as Done',
                              color: AppColors.primary,
                              onPressed: () => _updateStatus(appt.id, 'completed'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Helper: builds consistent action buttons
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(90, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}
