import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/features/client/bookings/client_appointment_details_screen.dart';
import 'package:sheersync/features/client/reviews/review_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = ['Upcoming', 'Pending', 'Completed', 'Cancelled'];
  
  // Filter states
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final appointmentsProvider = context.read<AppointmentsProvider>();
      
      if (authProvider.user != null) {
        // Load all client appointments with real-time updates
        appointmentsProvider.loadClientAppointments(authProvider.user!.id);
        appointmentsProvider.loadClientTodaysAppointments(authProvider.user!.id);
        appointmentsProvider.loadClientUpcomingAppointments(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsProvider = Provider.of<AppointmentsProvider>(context);
    Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchFilterBar(),
          // Tab Bar
          _buildTabBar(),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Tab
                _buildAppointmentsList(
                  _filterAppointments(
                    appointmentsProvider.allAppointments,
                    statusFilter: ['confirmed'],
                    isUpcoming: true,
                  ),
                  appointmentsProvider.isLoading,
                  'No upcoming appointments',
                  'You don\'t have any upcoming appointments scheduled.',
                ),
                // Pending Tab
                _buildAppointmentsList(
                  _filterAppointments(
                    appointmentsProvider.allAppointments,
                    statusFilter: ['pending'],
                  ),
                  appointmentsProvider.isLoading,
                  'No pending appointments',
                  'You don\'t have any pending appointment requests.',
                ),
                // Completed Tab
                _buildAppointmentsList(
                  _filterAppointments(
                    appointmentsProvider.allAppointments,
                    statusFilter: ['completed'],
                  ),
                  appointmentsProvider.isLoading,
                  'No completed appointments',
                  'Your completed appointments will appear here.',
                ),
                // Cancelled Tab
                _buildAppointmentsList(
                  _filterAppointments(
                    appointmentsProvider.allAppointments,
                    statusFilter: ['cancelled'],
                  ),
                  appointmentsProvider.isLoading,
                  'No cancelled appointments',
                  'Your cancelled appointments will appear here.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search appointments...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  selected: _selectedStatus == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? 'all' : 'all';
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'Today',
                  selected: _selectedDate != null && 
                      _selectedDate!.day == DateTime.now().day,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDate = selected ? DateTime.now() : null;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'This Week',
                  selected: _selectedDate != null && 
                      _isSameWeek(_selectedDate!, DateTime.now()),
                  onSelected: (selected) {
                    setState(() {
                      _selectedDate = selected ? DateTime.now() : null;
                    });
                  },
                ),
                // Add more filter chips as needed
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary.withOpacity(0.1),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.text,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    bool isLoading,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (appointments.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                  Text(
                    DateFormat('MMM d, yyyy').format(appointment.date),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Professional Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          appointment.serviceName ?? 'Service',
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
              const SizedBox(height: 12),
              // Time and Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('h:mm a').format(appointment.date),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (appointment.price != null)
                    Text(
                      'N\$${appointment.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              // Actions based on status
              if (appointment.status == 'pending') ..._buildPendingActions(appointment),
              if (appointment.status == 'confirmed') ..._buildConfirmedActions(appointment),
              if (appointment.status == 'completed') ..._buildCompletedActions(appointment),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPendingActions(AppointmentModel appointment) {
    return [
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancelAppointment(appointment),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
              child: const Text('Cancel Request'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rescheduleAppointment(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Reschedule'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildConfirmedActions(AppointmentModel appointment) {
    return [
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancelAppointment(appointment),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _viewAppointmentDetails(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCompletedActions(AppointmentModel appointment) {
    return [
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _bookAgain(appointment),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
              child: const Text('Book Again'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _leaveReview(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Leave Review'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(title),
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (title.contains('upcoming') || title.contains('pending'))
              ElevatedButton(
                onPressed: _bookNewAppointment,
                child: const Text('Book New Appointment'),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon(String title) {
    if (title.contains('upcoming')) return Icons.calendar_today_rounded;
    if (title.contains('pending')) return Icons.pending_actions_rounded;
    if (title.contains('completed')) return Icons.done_all_rounded;
    if (title.contains('cancelled')) return Icons.cancel_rounded;
    return Icons.calendar_today_rounded;
  }

  // Filtering methods
  List<AppointmentModel> _filterAppointments(
    List<AppointmentModel> appointments, {
    List<String>? statusFilter,
    bool isUpcoming = false,
  }) {
    var filtered = appointments.where((appointment) {
      // Status filter
      if (statusFilter != null && !statusFilter.contains(appointment.status)) {
        return false;
      }
      
      // Date filter
      if (_selectedDate != null) {
        if (_selectedDate!.day == DateTime.now().day) {
          // Today filter
          final appointmentDate = DateTime(
            appointment.date.year,
            appointment.date.month,
            appointment.date.day,
          );
          final today = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          if (appointmentDate != today) return false;
        } else if (_isSameWeek(_selectedDate!, appointment.date)) {
          // This week filter
          if (!_isSameWeek(appointment.date, DateTime.now())) return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesBarber = appointment.barberName?.toLowerCase().contains(query) ?? false;
        final matchesService = appointment.serviceName?.toLowerCase().contains(query) ?? false;
        if (!matchesBarber && !matchesService) return false;
      }
      
      // Upcoming filter
      if (isUpcoming && appointment.date.isBefore(DateTime.now())) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort by date
    filtered.sort((a, b) => a.date.compareTo(b.date));
    
    return filtered;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final startOfWeekA = a.subtract(Duration(days: a.weekday - 1));
    final startOfWeekB = b.subtract(Duration(days: b.weekday - 1));
    return startOfWeekA.difference(startOfWeekB).inDays == 0;
  }

  // Action methods
  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final appointmentsProvider = context.read<AppointmentsProvider>();
    
    if (authProvider.user != null) {
      appointmentsProvider.loadClientAppointments(authProvider.user!.id);
    }
  }

  void _viewAppointmentDetails(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientAppointmentDetailsScreen(appointment: appointment),
      ),
    );
  }

  void _cancelAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmCancelAppointment(appointment);
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

  void _confirmCancelAppointment(AppointmentModel appointment) {
    context.read<AppointmentsProvider>();
    
    // Show loading
    showCustomSnackBar(context, 'Cancelling appointment...', type: SnackBarType.info);
    
    // In a real app, you would call the repository to cancel the appointment
    // For now, we'll just show a success message
    Future.delayed(const Duration(seconds: 1), () {
      showCustomSnackBar(
        context,
        'Appointment cancelled successfully',
        type: SnackBarType.success,
      );
    });
  }

  void _rescheduleAppointment(AppointmentModel appointment) {
    showCustomSnackBar(
      context,
      'Reschedule functionality will be implemented',
      type: SnackBarType.info,
    );
  }

  void _bookAgain(AppointmentModel appointment) {
    showCustomSnackBar(
      context,
      'Book again functionality will be implemented',
      type: SnackBarType.info,
    );
  }

  void _leaveReview(AppointmentModel appointment) {
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

  void _bookNewAppointment() {
    // This will be handled by the FAB in the client shell
    showCustomSnackBar(
      context,
      'Use the + button to book a new appointment',
      type: SnackBarType.info,
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}