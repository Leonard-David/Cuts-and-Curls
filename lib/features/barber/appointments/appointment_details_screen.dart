import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/models/notification_model.dart';
import 'package:sheersync/data/repositories/booking_repository.dart';
import 'package:sheersync/data/repositories/notification_repository.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  bool _isLoading = false;

  Future<void> _updateAppointmentStatus(String status, {String? reason}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bookingRepository.updateAppointmentStatus(
        widget.appointment.id,
        status,
      );

      // Send notification to client
      final authProvider = context.read<AuthProvider>();
      final barber = authProvider.user!;

      await _notificationRepository.sendAppointmentNotification(
        userId: widget.appointment.clientId,
        appointmentId: widget.appointment.id,
        title: _getNotificationTitle(status, barber.fullName),
        message: _getNotificationMessage(status, reason),
        type: _getNotificationType(status),
      );

      if (mounted) {
        showCustomSnackBar(
          context,
          'Appointment ${status.replaceAll('_', ' ')}',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Failed to update appointment: $e',
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
      await _updateAppointmentStatus('cancelled');
    }
  }

  Future<void> _showDeclineDialog() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => DeclineReasonDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      await _updateAppointmentStatus('cancelled', reason: reason);
    }
  }

  Future<void> _markAsCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Are you sure you want to mark this appointment as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateAppointmentStatus('completed');
    }
  }

  String _getNotificationTitle(String status, String barberName) {
    switch (status) {
      case 'confirmed':
        return 'Appointment Confirmed!';
      case 'cancelled':
        return 'Appointment Cancelled';
      case 'completed':
        return 'Appointment Completed';
      default:
        return 'Appointment Update';
    }
  }

  String _getNotificationMessage(String status, String? reason) {
    switch (status) {
      case 'confirmed':
        return 'Your appointment has been confirmed by the barber';
      case 'cancelled':
        return reason ?? 'Your appointment has been cancelled by the barber';
      case 'completed':
        return 'Your appointment has been marked as completed';
      default:
        return 'Your appointment status has been updated';
    }
  }

  NotificationType _getNotificationType(String status) {
    switch (status) {
      case 'confirmed':
        return NotificationType.appointment;
      case 'cancelled':
        return NotificationType.system;
      case 'completed':
        return NotificationType.appointment;
      default:
        return NotificationType.system;
    }
  }

  bool _canEditAppointment() {
    return widget.appointment.status == 'pending' || 
           widget.appointment.status == 'confirmed';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isBarber = authProvider.user?.userType == 'barber' || 
                     authProvider.user?.userType == 'hairstylist';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
        actions: [
          if (isBarber && _canEditAppointment()) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _cancelAppointment();
                } else if (value == 'decline') {
                  _showDeclineDialog();
                } else if (value == 'complete') {
                  _markAsCompleted();
                } else {
                  _updateAppointmentStatus(value);
                }
              },
              itemBuilder: (context) => [
                if (widget.appointment.status == 'pending') ...[
                  const PopupMenuItem(
                    value: 'confirmed',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Confirm'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'decline',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Decline with Reason'),
                      ],
                    ),
                  ),
                ],
                if (widget.appointment.status == 'confirmed') ...[
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Mark as Completed'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancelled',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel Appointment'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
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
                  // Client/Barber Information
                  isBarber ? _buildClientInfo() : _buildBarberInfo(),
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
                  if (isBarber && _canEditAppointment()) _buildActionButtons(),
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

  Widget _buildClientInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
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
                widget.appointment.clientName ?? 'Client',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Client'),
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
              'Barber Information',
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
                widget.appointment.barberName ?? 'Barber',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Professional'),
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

  Widget _buildActionButtons() {
    if (widget.appointment.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showDeclineDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateAppointmentStatus('confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm'),
            ),
          ),
        ],
      );
    } else if (widget.appointment.status == 'confirmed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelAppointment,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _markAsCompleted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mark Complete'),
            ),
          ),
        ],
      );
    }
    
    return Container(); // No actions for other statuses
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
        return 'Appointment has been confirmed';
      case 'pending':
        return 'Waiting for confirmation';
      case 'completed':
        return 'Service has been completed';
      case 'cancelled':
        return 'Appointment has been cancelled';
      default:
        return 'Unknown status';
    }
  }
}

class DeclineReasonDialog extends StatefulWidget {
  @override
  State<DeclineReasonDialog> createState() => _DeclineReasonDialogState();
}

class _DeclineReasonDialogState extends State<DeclineReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = '';

  final List<String> _commonReasons = [
    'Not available at this time',
    'Fully booked',
    'Service not offered',
    'Outside working hours',
    'Other reason'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline Appointment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for declining this appointment:'),
          const SizedBox(height: 16),
          ..._commonReasons.map((reason) {
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value!;
                  if (reason != 'Other reason') {
                    _reasonController.text = reason;
                  } else {
                    _reasonController.clear();
                  }
                });
              },
            );
          }),
          if (_selectedReason == 'Other reason') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _reasonController.text.isEmpty ? null : () {
            Navigator.pop(context, _reasonController.text);
          },
          child: const Text('Decline Appointment'),
        ),
      ],
    );
  }
}