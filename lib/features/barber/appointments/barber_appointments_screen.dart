import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/features/barber/appointments/create_appointment_screen.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../features/auth/controllers/auth_provider.dart';
import 'appointment_details_screen.dart';

class BarberAppointmentsScreen extends StatefulWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  State<BarberAppointmentsScreen> createState() => _BarberAppointmentsScreenState();
}

class _BarberAppointmentsScreenState extends State<BarberAppointmentsScreen> with SingleTickerProviderStateMixin {
  final BookingRepository _bookingRepository = BookingRepository();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final appointmentsProvider = context.read<AppointmentsProvider>();
      final barberId = authProvider.user?.id;
      
      if (barberId != null) {
        appointmentsProvider.refreshAll(barberId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appointmentsProvider = Provider.of<AppointmentsProvider>(context);
    final barberId = authProvider.user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointments Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateAppointmentScreen(),
                ),
              );
            },
            tooltip: 'Create New Appointment',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (barberId != null) {
                appointmentsProvider.refreshAll(barberId);
                showCustomSnackBar(
                  context,
                  'Appointments refreshed',
                  type: SnackBarType.success,
                );
              }
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Requests'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: barberId == null
          ? _buildErrorState('Please login again')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodaysAppointments(barberId, appointmentsProvider),
                _buildUpcomingAppointments(barberId, appointmentsProvider),
                _buildAppointmentRequests(barberId, appointmentsProvider),
                _buildAllAppointments(barberId, appointmentsProvider),
              ],
            ),
    );
  }

  Widget _buildTodaysAppointments(String barberId, AppointmentsProvider provider) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _bookingRepository.getTodaysAppointments(barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final appointments = snapshot.data ?? [];
        
        if (appointments.isEmpty) {
          return _buildEmptyState(
            title: 'No Appointments Today',
            message: 'You have no appointments scheduled for today',
            icon: Icons.calendar_today,
          );
        }

        return _buildAppointmentsList(appointments);
      },
    );
  }

  Widget _buildUpcomingAppointments(String barberId, AppointmentsProvider provider) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _bookingRepository.getUpcomingAppointments(barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final appointments = snapshot.data ?? [];
        
        if (appointments.isEmpty) {
          return _buildEmptyState(
            title: 'No Upcoming Appointments',
            message: 'You have no upcoming appointments in the next 7 days',
            icon: Icons.upcoming,
          );
        }

        return _buildAppointmentsList(appointments);
      },
    );
  }

  Widget _buildAppointmentRequests(String barberId, AppointmentsProvider provider) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _bookingRepository.getAppointmentRequests(barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final requests = snapshot.data ?? [];
        
        if (requests.isEmpty) {
          return _buildEmptyState(
            title: 'No Pending Requests',
            message: 'You have no pending appointment requests',
            icon: Icons.pending_actions,
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppColors.accent.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have ${requests.length} pending appointment request${requests.length > 1 ? 's' : ''}',
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildAppointmentsList(requests),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllAppointments(String barberId, AppointmentsProvider provider) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _bookingRepository.getBarberAppointments(barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final appointments = snapshot.data ?? [];
        
        if (appointments.isEmpty) {
          return _buildEmptyState(
            title: 'No Appointments',
            message: 'You don\'t have any appointments yet',
            icon: Icons.calendar_month,
          );
        }

        return _buildAppointmentsList(appointments);
      },
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading appointments',
            style: TextStyle(
              color: AppColors.error, 
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final isToday = _isToday(appointment.date);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _viewAppointmentDetails(appointment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // Appointment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appointment.clientName ?? 'Client',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isToday) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.serviceName ?? 'Service',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(appointment.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointment.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(appointment.status).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(appointment.status),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'N\$${appointment.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    // Reminder indicator
                    if (appointment.hasReminder && appointment.reminderMinutes != null) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'Reminder: ${appointment.reminderMinutes}min before',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewAppointmentDetails(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(appointment: appointment),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}