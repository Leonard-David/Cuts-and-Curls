import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/features/client/reviews/review_screen.dart';

class ClientAppointmentDetailsScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const ClientAppointmentDetailsScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final appointmentsProvider = Provider.of<AppointmentsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (appointment.status == 'pending' || appointment.status == 'confirmed')
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, context, appointmentsProvider),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reschedule',
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 8),
                      Text('Reschedule'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel),
                      SizedBox(width: 8),
                      Text('Cancel Appointment'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),
            // Appointment Details Card
            _buildDetailsCard(),
            const SizedBox(height: 16),
            // Professional Info Card
            _buildProfessionalCard(),
            const SizedBox(height: 16),
            // Service Details Card
            _buildServiceCard(),
            const SizedBox(height: 16),
            // Actions Card
            _buildActionsCard(context, appointmentsProvider, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(appointment.status),
                size: 32,
                color: _getStatusColor(appointment.status),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              appointment.status.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(appointment.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(appointment.status),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Date', DateFormat('EEEE, MMMM d, yyyy').format(appointment.date)),
            _buildDetailRow('Time', DateFormat('h:mm a').format(appointment.date)),
            _buildDetailRow('Duration', '${appointment.reminderMinutes ?? 30} minutes'),
            _buildDetailRow('Created', DateFormat('MMM d, yyyy • h:mm a').format(appointment.createdAt)),
            if (appointment.updatedAt != null)
              _buildDetailRow('Last Updated', DateFormat('MMM d, yyyy • h:mm a').format(appointment.updatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Professional',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.barberName ?? 'Professional',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Barber',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '4.8', // This would come from barber data
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(124 reviews)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewProfessionalProfile(),
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _messageProfessional(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Service', appointment.serviceName ?? 'Haircut'),
            if (appointment.price != null)
              _buildDetailRow('Price', 'N\$${appointment.price!.toStringAsFixed(2)}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildDetailRow('Notes', appointment.notes!),
            if (appointment.hasReminder && appointment.reminderMinutes != null)
              _buildDetailRow('Reminder', '${appointment.reminderMinutes} minutes before'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, AppointmentsProvider appointmentsProvider, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (appointment.status == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _rescheduleAppointment(context),
                  child: const Text('Reschedule Appointment'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelAppointment(context, appointmentsProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Cancel Appointment'),
                ),
              ),
            ],
            if (appointment.status == 'confirmed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addToCalendar(),
                  child: const Text('Add to Calendar'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelAppointment(context, appointmentsProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Cancel Appointment'),
                ),
              ),
            ],
            if (appointment.status == 'completed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _leaveReview(context, authProvider),
                  child: const Text('Leave Review'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _bookAgain(),
                  child: const Text('Book Again'),
                ),
              ),
            ],
            if (appointment.status == 'cancelled') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookAgain(),
                  child: const Text('Book New Appointment'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _contactSupport(),
                child: const Text('Contact Support'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value, BuildContext context, AppointmentsProvider appointmentsProvider) {
    switch (value) {
      case 'reschedule':
        _rescheduleAppointment(context);
        break;
      case 'cancel':
        _cancelAppointment(context, appointmentsProvider);
        break;
    }
  }

  void _rescheduleAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text('This feature will allow you to choose a new date and time for your appointment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showCustomSnackBar(
                context,
                'Reschedule functionality will be implemented',
                type: SnackBarType.info,
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(BuildContext context, AppointmentsProvider appointmentsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmCancelAppointment(context, appointmentsProvider);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelAppointment(BuildContext context, AppointmentsProvider appointmentsProvider) {
    // Show loading
    showCustomSnackBar(context, 'Cancelling appointment...', type: SnackBarType.info);
    
    // Cancel the appointment
    appointmentsProvider.cancelAppointment(appointment.id).then((_) {
      showCustomSnackBar(
        context,
        'Appointment cancelled successfully',
        type: SnackBarType.success,
      );
    }).catchError((error) {
      showCustomSnackBar(
        context,
        'Failed to cancel appointment: $error',
        type: SnackBarType.error,
      );
    });
  }

  void _viewProfessionalProfile() {
    showCustomSnackBar(
      navigatorKey.currentContext!,
      'Professional profile view will be implemented',
      type: SnackBarType.info,
    );
  }

  void _messageProfessional() {
    showCustomSnackBar(
      navigatorKey.currentContext!,
      'Messaging functionality will be implemented',
      type: SnackBarType.info,
    );
  }

  void _addToCalendar() {
    showCustomSnackBar(
      navigatorKey.currentContext!,
      'Calendar integration will be implemented',
      type: SnackBarType.info,
    );
  }

  void _leaveReview(BuildContext context, AuthProvider authProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          barberId: appointment.barberId,
          appointmentId: appointment.id,
          barberName: appointment.barberName ?? 'Professional',
        ),
      ),
    );
  }

  void _bookAgain() {
    showCustomSnackBar(
      navigatorKey.currentContext!,
      'Book again functionality will be implemented',
      type: SnackBarType.info,
    );
  }

  void _contactSupport() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For assistance with this appointment, please contact our support team:\n\n'
          'Email: support@sheersync.com\n'
          'Phone: +1-555-HELP\n\n'
          'Please have your appointment ID ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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

  String _getStatusDescription(String status) {
    switch (status) {
      case 'confirmed':
        return 'Your appointment has been confirmed by the professional';
      case 'pending':
        return 'Waiting for professional to confirm your appointment';
      case 'completed':
        return 'This appointment has been completed';
      case 'cancelled':
        return 'This appointment has been cancelled';
      default:
        return 'Unknown appointment status';
    }
  }
}

// Global key for navigation context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();