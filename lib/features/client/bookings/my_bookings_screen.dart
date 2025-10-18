// lib/features/client/bookings/my_bookings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/booking_repository.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _cancelBooking(String appointmentId) async {
    try {
      await _bookingRepo.updateAppointmentStatus(appointmentId, 'cancelled');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel booking')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view bookings.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('My Appointments'),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _bookingRepo.getClientAppointments(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no bookings yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final formattedDate =
                  '${booking.appointmentDate.day}/${booking.appointmentDate.month}/${booking.appointmentDate.year}';
              final formattedTime =
                  '${booking.appointmentDate.hour.toString().padLeft(2, '0')}:${booking.appointmentDate.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    booking.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Date: $formattedDate at $formattedTime'),
                      Text('Price: \$${booking.price}'),
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${booking.status.toUpperCase()}',
                        style: TextStyle(
                          color: _statusColor(booking.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (booking.notes != null && booking.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Notes: ${booking.notes}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: booking.status == 'pending'
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancel Booking'),
                                content: const Text(
                                    'Are you sure you want to cancel this booking?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Yes, Cancel'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _cancelBooking(booking.id);
                            }
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Assigns colors based on booking status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blueGrey;
      default:
        return AppColors.textSecondary;
    }
  }
}
