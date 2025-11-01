import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../features/auth/controllers/auth_provider.dart';
import 'appointment_details_screen.dart';

class BarberAppointmentsScreen extends StatefulWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  State<BarberAppointmentsScreen> createState() => _BarberAppointmentsScreenState();
}

class _BarberAppointmentsScreenState extends State<BarberAppointmentsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  String _selectedFilter = 'today'; // today, upcoming, all

  Map<String, String> _filters = {
    'today': 'Today',
    'upcoming': 'Upcoming',
    'all': 'All Appointments',
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barberId = authProvider.user?.id;

    if (barberId == null) {
      return const Center(child: Text('Please login again'));
    }

    return Scaffold(
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 16),
          // Appointments List
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _bookingRepository.getBarberAppointments(barberId),
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

                return _buildAppointmentsList(appointments);
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
            'No Appointments',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have any appointments yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
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
            'No ${_filters[_selectedFilter]?.toLowerCase()}',
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

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 8,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              // Appointment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.clientName ?? 'Client',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.serviceName ?? 'Service',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(appointment.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'N\$${appointment.price?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
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

  List<AppointmentModel> _filterAppointments(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case 'today':
        return appointments.where((appt) {
          return appt.date.isAfter(todayStart) && appt.date.isBefore(todayEnd);
        }).toList();
      case 'upcoming':
        return appointments.where((appt) {
          return appt.date.isAfter(now) && appt.status != 'completed' && appt.status != 'cancelled';
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
}