import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/payment_model.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/repositories/payment_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import '../../../data/models/appointment_model.dart';
import '../payments/payments_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  String _selectedFilter = 'upcoming'; // upcoming, past, cancelled

  Map<String, String> _filters = {
    'upcoming': 'Upcoming',
    'past': 'Past',
    'cancelled': 'Cancelled',
    'all': 'All',
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clientId = authProvider.user?.id;

    if (clientId == null) {
      return const Center(child: Text('Please login again'));
    }

    return Scaffold(
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 16),
          // Bookings List
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _bookingRepository.getClientAppointments(clientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final appointments = _filterAppointments(snapshot.data!);
                
                if (appointments.isEmpty) {
                  return _buildEmptyFilterState();
                }

                return _buildBookingsList(appointments);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(entry.value),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = entry.key;
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Bookings Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book your first appointment with a barber',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to home to book
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${_filters[_selectedFilter]?.toLowerCase()} bookings',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try selecting a different filter',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<AppointmentModel> appointments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return FutureBuilder<PaymentModel?>(
          future: _paymentRepository.getPaymentByAppointment(appointment.id),
          builder: (context, paymentSnapshot) {
            return _buildBookingCard(appointment, paymentSnapshot.data);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(AppointmentModel appointment, PaymentModel? payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Barber Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.barberName ?? 'Barber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Service and Time
            Row(
              children: [
                Icon(Icons.cut, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.serviceName ?? 'Service',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(appointment.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment Status and Actions
            _buildBookingActions(appointment, payment),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingActions(AppointmentModel appointment, PaymentModel? payment) {
    final now = DateTime.now();
    final canCancel = appointment.status == 'pending' || 
                     appointment.status == 'confirmed';
    final canPay = appointment.status == 'confirmed' && 
                  (payment == null || payment.status == 'pending');
    final isUpcoming = appointment.date.isAfter(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Payment Status
        if (payment != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getPaymentStatusIcon(payment.status),
                  size: 12,
                  color: _getPaymentStatusColor(payment.status),
                ),
                const SizedBox(width: 4),
                Text(
                  'Payment ${payment.status}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPaymentStatusColor(payment.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else if (appointment.status == 'confirmed')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.payment, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Payment Required',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Container(),

        // Action Buttons
        Row(
          children: [
            if (canCancel && isUpcoming)
              OutlinedButton(
                onPressed: () => _cancelBooking(appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Cancel'),
              ),
            if (canPay)
              const SizedBox(width: 8),
            if (canPay)
              ElevatedButton(
                onPressed: () => _makePayment(appointment, payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Pay Now'),
              ),
          ],
        ),
      ],
    );
  }

  void _cancelBooking(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingRepository.cancelAppointment(appointment.id);
        showCustomSnackBar(
          context,
          'Booking cancelled successfully',
          type: SnackBarType.success,
        );
      } catch (e) {
        showCustomSnackBar(
          context,
          'Failed to cancel booking: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _makePayment(AppointmentModel appointment, PaymentModel? existingPayment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentsScreen(
          appointment: appointment,
          existingPayment: existingPayment,
        ),
      ),
    );
  }

  List<AppointmentModel> _filterAppointments(List<AppointmentModel> appointments) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'upcoming':
        return appointments.where((appt) {
          return appt.date.isAfter(now) && 
                 appt.status != 'cancelled' && 
                 appt.status != 'completed';
        }).toList();
      case 'past':
        return appointments.where((appt) {
          return appt.date.isBefore(now) || 
                 appt.status == 'completed';
        }).toList();
      case 'cancelled':
        return appointments.where((appt) {
          return appt.status == 'cancelled';
        }).toList();
      case 'all':
      default:
        return appointments;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.help;
    }
  }
}