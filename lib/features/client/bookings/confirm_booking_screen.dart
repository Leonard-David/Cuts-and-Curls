// lib/features/client/bookings/confirm_booking_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/booking_repository.dart';
import 'my_bookings_screen.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String barberId;
  final Map<String, dynamic> barberData;
  final String serviceId;
  final Map<String, dynamic> serviceData;

  const ConfirmBookingScreen({
    super.key,
    required this.barberId,
    required this.barberData,
    required this.serviceId,
    required this.serviceData,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final appointmentDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (appointmentDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future time.')),
      );
      return;
    }

    final newBooking = AppointmentModel(
      id: '',
      clientId: user.uid,
      barberId: widget.barberId,
      serviceId: widget.serviceId,
      serviceName: widget.serviceData['name'] ?? 'Service',
      price: (widget.serviceData['price'] ?? 0).toDouble(),
      appointmentDate: appointmentDate,
      status: 'pending',
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() => _isLoading = true);

    try {
      final bookingRepo = BookingRepository();
      await bookingRepo.createAppointment(newBooking);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to client's booking list
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        (route) => false,
      );
    } catch (e, st) {
      debugPrint('Booking error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm booking. Try again later.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.serviceData;
    final barber = widget.barberData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Confirm Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barber Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: barber['profileImage'] != null
                        ? NetworkImage(barber['profileImage'])
                        : const AssetImage('lib/assets/images/icon/icon.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      barber['displayName'] ?? 'Barber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Service Info
              Text(
                service['name'] ?? 'Service',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(service['description'] ?? ''),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price: \$${service['price']}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Duration: ${service['duration']} min'),
                ],
              ),
              const SizedBox(height: 24),

              // Date and time pickers
              ListTile(
                title: const Text('Select Date'),
                subtitle: Text(_selectedDate == null
                    ? 'No date selected'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                title: const Text('Select Time'),
                subtitle: Text(_selectedTime == null
                    ? 'No time selected'
                    : _selectedTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              const SizedBox(height: 20),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Confirm button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Booking'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
