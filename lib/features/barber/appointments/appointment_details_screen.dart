import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../core/widgets/custom_snackbar.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  bool _isLoading = false;

  Future<void> _updateAppointmentStatus(String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bookingRepository.updateAppointmentStatus(
        widget.appointment.id,
        status,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (widget.appointment.status == 'pending') ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _cancelAppointment();
                } else {
                  _updateAppointmentStatus(value);
                }
              },
              itemBuilder: (context) => [
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
                  value: 'cancelled',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel'),
                    ],
                  ),
                ),
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
                  // Client Information
                  _buildClientInfo(),
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
                  if (widget.appointment.status == 'pending') _buildActionButtons(),
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
                    widget.appointment.status.toUpperCase(),
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
                      color: Colors.grey[600],
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
              leading: const CircleAvatar(
                child: Icon(Icons.person),
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
                Text(
                  widget.appointment.serviceName ?? 'Service',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade400),
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
                Icon(Icons.access_time, color: Colors.blue.shade400),
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
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelAppointment,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel Appointment'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateAppointmentStatus('confirmed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
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