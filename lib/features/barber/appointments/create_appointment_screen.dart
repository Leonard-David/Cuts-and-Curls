import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _hasReminder = false;
  int _reminderMinutes = 30;
  String? _reminderNote;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  
                  // Client Information
                  _buildSectionCard(
                    title: 'Client Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name *',
                          hintText: 'Enter client full name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter client name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Service Information
                  _buildSectionCard(
                    title: 'Service Details',
                    icon: Icons.construction_rounded,
                    children: [
                      TextFormField(
                        controller: _serviceNameController,
                        decoration: const InputDecoration(
                          labelText: 'Service Name *',
                          hintText: 'e.g., Classic Haircut, Hair Coloring',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter service name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (N\$) *',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money_rounded),
                          prefixText: 'N\$',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter valid price';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date & Time Selection
                  _buildSectionCard(
                    title: 'Schedule',
                    icon: Icons.calendar_today_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateTimeTile(
                              icon: Icons.calendar_today_rounded,
                              title: 'Date',
                              subtitle: DateFormat('MMM d, yyyy').format(_selectedDate),
                              onTap: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateTimeTile(
                              icon: Icons.access_time_rounded,
                              title: 'Time',
                              subtitle: _selectedTime.format(context),
                              onTap: _selectTime,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reminder Settings
                  _buildSectionCard(
                    title: 'Reminder Settings',
                    icon: Icons.notifications_active_rounded,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set Appointment Reminder',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  _hasReminder 
                                      ? 'You will be reminded before the appointment'
                                      : 'No reminder set',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _hasReminder,
                            onChanged: (value) {
                              setState(() {
                                _hasReminder = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      
                      if (_hasReminder) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Remind me before appointment:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _reminderMinutes,
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                            DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                            DropdownMenuItem(value: 60, child: Text('1 hour before')),
                            DropdownMenuItem(value: 120, child: Text('2 hours before')),
                            DropdownMenuItem(value: 1440, child: Text('1 day before')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _reminderMinutes = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          onChanged: (value) => _reminderNote = value,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Reminder Note (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'Add a note for the reminder...',
                            prefixIcon: Icon(Icons.note_add_outlined),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional Notes
                  _buildSectionCard(
                    title: 'Additional Notes',
                    icon: Icons.notes_rounded,
                    children: [
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add any additional notes about this appointment...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _createAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Create Appointment',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Schedule a new appointment with your client',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final appointmentsProvider = context.read<AppointmentsProvider>();
      final barber = authProvider.user!;

      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointment = AppointmentModel(
        id: 'appt_${DateTime.now().millisecondsSinceEpoch}_${_clientNameController.text.replaceAll(' ', '_')}',
        barberId: barber.id,
        clientId: 'manual_${DateTime.now().millisecondsSinceEpoch}', // Mark as manually created
        clientName: _clientNameController.text.trim(),
        barberName: barber.fullName,
        date: appointmentDateTime,
        serviceName: _serviceNameController.text.trim(),
        price: double.parse(_priceController.text),
        status: 'confirmed', // Auto-confirm barber-created appointments
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        hasReminder: _hasReminder,
        reminderMinutes: _hasReminder ? _reminderMinutes : null,
        reminderNote: _reminderNote,
      );

      await _bookingRepository.createAppointment(appointment);

      // Update local state for immediate UI update
      appointmentsProvider.addAppointment(appointment);

      if (mounted) {
        showCustomSnackBar(
          context,
          'Appointment created successfully!',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Failed to create appointment: $e',
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

  @override
  void dispose() {
    _clientNameController.dispose();
    _serviceNameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}