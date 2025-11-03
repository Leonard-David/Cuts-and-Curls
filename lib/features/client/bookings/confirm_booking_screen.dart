import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/notification_model.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/repositories/notification_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final UserModel barber;
  final ServiceModel service;

  const ConfirmBookingScreen({
    super.key,
    required this.barber,
    required this.service,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  List<DateTime> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null) return;

    try {
      final slots = await _bookingRepository.getAvailableTimeSlots(
        widget.barber.id,
        _selectedDate!,
      );
      setState(() {
        _availableSlots = slots;
      });
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to load available slots',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      showCustomSnackBar(
        context,
        'Please select date and time',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final client = authProvider.user!;

      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create appointment
      final appointment = AppointmentModel(
        id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
        barberId: widget.barber.id,
        clientId: client.id,
        clientName: client.fullName,
        barberName: widget.barber.fullName,
        date: appointmentDateTime,
        serviceName: widget.service.name,
        price: widget.service.price,
        status: 'pending',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _bookingRepository.createAppointment(appointment);

      // Send notification to barber
      await _notificationRepository.sendAppointmentNotification(
        userId: widget.barber.id,
        appointmentId: appointment.id,
        title: 'New Appointment Request',
        message: '${client.fullName} requested a ${widget.service.name} appointment',
        type: NotificationType.appointment,
      );

      if (mounted) {
        showCustomSnackBar(
          context,
          'Appointment booked successfully! The barber will confirm shortly.',
          type: SnackBarType.success,
        );
        
        // Navigate back to home screen
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Failed to book appointment: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableSlots = [];
      });
      _loadAvailableSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            _buildBookingSummary(),
            const SizedBox(height: 24),
            // Date Selection
            _buildDateSelection(),
            const SizedBox(height: 24),
            // Time Selection
            _buildTimeSelection(),
            const SizedBox(height: 24),
            // Additional Notes
            _buildNotesSection(),
            const SizedBox(height: 32),
            // Confirm Button
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.barber.profileImage != null
                      ? NetworkImage(widget.barber.profileImage!)
                      : null,
                  child: widget.barber.profileImage == null
                      ? Icon(Icons.person, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.barber.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.service.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'N\$${widget.service.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${widget.service.duration} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'N\$${widget.service.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text(
              _selectedDate == null
                  ? 'Select a date'
                  : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!),
              style: TextStyle(
                fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedDate == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Please select a date first',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else if (_availableSlots.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No available slots for selected date',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedTime == slot;

              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedTime = slot;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceLight,
                  foregroundColor: isSelected ? AppColors.onPrimary : AppColors.text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  DateFormat('h:mm a').format(slot),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special requests or notes for the barber...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _confirmBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Text(
              'Confirm Booking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}