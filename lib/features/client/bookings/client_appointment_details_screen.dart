import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/repositories/chat_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/shared/chat/chat_screen.dart';

class ClientAppointmentDetailsScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const ClientAppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<ClientAppointmentDetailsScreen> createState() => _ClientAppointmentDetailsScreenState();
}

class _ClientAppointmentDetailsScreenState extends State<ClientAppointmentDetailsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final ChatRepository _chatRepository = ChatRepository();
  bool _isLoading = false;

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
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
      setState(() {
        _isLoading = true;
      });

      try {
        await _bookingRepository.cancelAppointment(widget.appointment.id);
        
        if (mounted) {
          showCustomSnackBar(
            context,
            'Appointment cancelled successfully',
            type: SnackBarType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Failed to cancel appointment: $e',
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
  }

  Future<void> _contactBarber() async {
    final authProvider = context.read<AuthProvider>();
    final client = authProvider.user!;

    try {
      final chatRoom = await _chatRepository.getOrCreateChatRoom(
        clientId: client.id,
        clientName: client.fullName,
        barberId: widget.appointment.barberId,
        barberName: widget.appointment.barberName ?? 'Barber',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoom: chatRoom),
        ),
      );
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to start chat: $e',
        type: SnackBarType.error,
      );
    }
  }

  bool _canCancelAppointment() {
    final now = DateTime.now();
    final isUpcoming = widget.appointment.date.isAfter(now);
    return (widget.appointment.status == 'pending' || widget.appointment.status == 'confirmed') && isUpcoming;
  }

  @override
  Widget build(BuildContext context) {
    final isPast = widget.appointment.date.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
        actions: [
          if (_canCancelAppointment())
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelAppointment,
              tooltip: 'Cancel Appointment',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  // Barber Information
                  _buildBarberInfo(),
                  const SizedBox(height: 24),
                  // Service Information
                  _buildServiceInfo(),
                  const SizedBox(height: 24),
                  // Appointment Time
                  _buildAppointmentTime(),
                  if (widget.appointment.notes != null) ...[
                    const SizedBox(height: 24),
                    // Additional Notes
                    _buildAdditionalNotes(),
                  ],
                  const SizedBox(height: 32),
                  // Action Buttons
                  _buildActionButtons(isPast),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _getStatusColor(widget.appointment.status).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(widget.appointment.status),
              color: _getStatusColor(widget.appointment.status),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(widget.appointment.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.appointment.status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(widget.appointment.status),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarberInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Professional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(
                widget.appointment.barberName ?? 'Professional',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Your service provider'),
              trailing: IconButton(
                icon: Icon(Icons.chat, color: AppColors.primary),
                onPressed: _contactBarber,
                tooltip: 'Contact Professional',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appointment.serviceName ?? 'Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.appointment.serviceName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Service booked',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  'N\$${widget.appointment.price?.toStringAsFixed(2) ?? '0.00'}',
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

  Widget _buildAppointmentTime() {
    final isPast = widget.appointment.date.isBefore(DateTime.now());
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointment Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPast) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Past',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(widget.appointment.date),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('h:mm a').format(widget.appointment.date),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalNotes() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.appointment.notes!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isPast) {
    return Column(
      children: [
        if (_canCancelAppointment())
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancelAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel Appointment'),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _contactBarber,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Contact Professional'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.accent;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'confirmed':
        return 'Your appointment has been confirmed by the professional';
      case 'pending':
        return 'Waiting for professional confirmation';
      case 'completed':
        return 'Service has been completed';
      case 'cancelled':
        return 'Appointment has been cancelled';
      default:
        return 'Unknown status';
    }
  }
}