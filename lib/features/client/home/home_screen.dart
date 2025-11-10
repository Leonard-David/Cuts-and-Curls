import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/features/barber/profile/barber_profile_screen.dart';
import 'package:sheersync/features/client/bookings/client_appointment_details_screen.dart';
import 'package:sheersync/features/client/bookings/select_barber_screen.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';
import 'package:sheersync/features/client/reviews/special_offers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _availableBarbers = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<Map<String, dynamic>> _activeOffers = [];
  bool _isLoading = true;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<UserModel>>? _barbersSubscription;
  StreamSubscription<List<AppointmentModel>>? _appointmentsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _offersSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRealTimeData();
  }

  @override
  void dispose() {
    _barbersSubscription?.cancel();
    _appointmentsSubscription?.cancel();
    _offersSubscription?.cancel();
    super.dispose();
  }

  void _initializeRealTimeData() {
    _loadAvailableBarbers();
    _loadUpcomingAppointments();
    _loadActiveOffers();
  }

  void _loadAvailableBarbers() {
    _barbersSubscription?.cancel();

    _barbersSubscription = _firestore
        .collection('users')
        .where('userType', whereIn: ['barber', 'hairstylist'])
        .where('isOnline', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final barbers = snapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromMap({...data, 'id': doc.id});
          }).toList();

          // Filter barbers who are actually available (not fully booked)
          final availableBarbers = await _filterTrulyAvailableBarbers(barbers);
          return availableBarbers;
        })
        .listen((barbers) {
          if (mounted) {
            setState(() {
              _availableBarbers = barbers;
              _checkLoadingState();
            });
          }
        }, onError: (error) {
          print('Error loading barbers: $error');
          if (mounted) {
            setState(() {
              _checkLoadingState();
            });
          }
        });
  }

  Future<List<UserModel>> _filterTrulyAvailableBarbers(
      List<UserModel> barbers) async {
    final availableBarbers = <UserModel>[];
    // ignore: unused_local_variable
    final now = DateTime.now();

    for (final barber in barbers) {
      try {
        // Check if barber has available slots today or tomorrow
        final isAvailable = await _checkBarberAvailability(barber.id);
        if (isAvailable) {
          availableBarbers.add(barber);
        }
      } catch (e) {
        // If check fails, include barber anyway
        availableBarbers.add(barber);
        print('Error checking availability for ${barber.fullName}: $e');
      }
    }

    return availableBarbers;
  }

  Future<bool> _checkBarberAvailability(String barberId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Check for appointments in the next 2 days
      final appointments = await _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('date', isGreaterThanOrEqualTo: today.millisecondsSinceEpoch)
          .where('date',
              isLessThan:
                  tomorrow.add(const Duration(days: 2)).millisecondsSinceEpoch)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      // Consider barber available if they have less than 8 appointments per day
      final appointmentCount = appointments.docs.length;
      return appointmentCount < 16; // 8 per day for 2 days
    } catch (e) {
      return true; // Default to available if check fails
    }
  }

  void _loadUpcomingAppointments() {
    _appointmentsSubscription?.cancel();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    _appointmentsSubscription = _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: authProvider.user!.id)
        .where('status', whereIn: ['pending', 'confirmed'])
        .where('date',
            isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return AppointmentModel.fromMap({...data, 'id': doc.id});
          }).toList();
        })
        .listen((appointments) {
          if (mounted) {
            setState(() {
              _upcomingAppointments = appointments;
              _checkLoadingState();
            });
          }
        }, onError: (error) {
          print('Error loading appointments: $error');
          if (mounted) {
            setState(() {
              _checkLoadingState();
            });
          }
        });
  }

  void _loadActiveOffers() {
    _offersSubscription?.cancel();

    _offersSubscription = _firestore
        .collection('marketing_offers')
        .where('isActive', isEqualTo: true)
        .where('expiresAt',
            isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .listen((offers) {
      if (mounted) {
        setState(() {
          _activeOffers = offers;
          _checkLoadingState();
        });
      }
    }, onError: (error) {
      print('Error loading offers: $error');
      if (mounted) {
        setState(() {
          _checkLoadingState();
        });
      }
    });
  }

  void _checkLoadingState() {
    if (_availableBarbers.isNotEmpty ||
        _upcomingAppointments.isNotEmpty ||
        _activeOffers.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    Provider.of<AppointmentsProvider>(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(authProvider),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Available Professionals Section
            _buildAvailableProfessionalsSection(),
            const SizedBox(height: 24),

            // Upcoming Appointments
            _buildUpcomingAppointmentsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    _initializeRealTimeData();
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
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
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: authProvider.user?.profileImage != null
                ? CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        NetworkImage(authProvider.user!.profileImage!),
                  )
                : Icon(
                    Icons.person,
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
                  'Welcome back, ${authProvider.user?.fullName ?? 'Client'}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for your next grooming session?',
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.search_rounded,
                title: 'Find Professionals',
                subtitle: 'Browse barbers & stylists',
                color: AppColors.primary,
                onTap: _navigateToFindProfessionals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.local_offer_rounded,
                title: 'Special Offers',
                subtitle: 'View discounts & deals',
                color: AppColors.accent,
                onTap: _navigateToSpecialOffers,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableProfessionalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Professionals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            TextButton(
              onPressed: _navigateToAllProfessionals,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoading
            ? _buildLoadingProfessionals()
            : _availableBarbers.isEmpty
                ? _buildNoProfessionalsAvailable()
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableBarbers.length,
                      itemBuilder: (context, index) {
                        final barber = _availableBarbers[index];
                        return _buildProfessionalCard(barber);
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildProfessionalCard(UserModel barber) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _viewBarberProfile(barber),
          onLongPress: () => _showBarberQuickActions(barber),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Professional Avatar with Online Status
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: barber.profileImage != null
                                ? NetworkImage(barber.profileImage!)
                                : null,
                            child: barber.profileImage == null
                                ? Icon(Icons.person,
                                    size: 40, color: AppColors.textSecondary)
                                : null,
                          ),
                          // Online Status Indicator
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: barber.isOnline
                                  ? AppColors.success
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Professional Name
                    Text(
                      barber.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    // Professional Type
                    Text(
                      barber.userType == 'barber'
                          ? 'Professional Barber'
                          : 'Hairstylist',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          barber.rating?.toStringAsFixed(1) ?? '0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${barber.totalRatings ?? 0})',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildUpcomingAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            TextButton(
              onPressed: _navigateToAllAppointments,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _upcomingAppointments.isEmpty
            ? _buildNoUpcomingAppointments()
            : Column(
                children: _upcomingAppointments
                    .map((appointment) => _buildAppointmentItem(appointment))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildAppointmentItem(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStatusIcon(appointment.status),
            color: _getStatusColor(appointment.status),
            size: 20,
          ),
        ),
        title: Text(
          appointment.barberName ?? 'Professional',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.serviceName ?? 'Service',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(appointment.date),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            appointment.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _getStatusColor(appointment.status),
            ),
          ),
        ),
        onTap: () => _viewAppointmentDetails(appointment),
      ),
    );
  }

  // Loading and Empty States
  Widget _buildLoadingProfessionals() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    CircleAvatar(radius: 40, backgroundColor: Colors.grey),
                    SizedBox(height: 8),
                    SizedBox(height: 10, child: LinearProgressIndicator()),
                    SizedBox(height: 4),
                    SizedBox(height: 8, child: LinearProgressIndicator()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoProfessionalsAvailable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.person_off_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No Professionals Available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for available barbers and hairstylists',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _navigateToAllProfessionals,
            child: const Text('Browse All Professionals'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingAppointments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No Upcoming Appointments',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first appointment to get started',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _navigateToQuickBooking,
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToFindProfessionals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectBarberScreen()),
    );
  }

  void _navigateToSpecialOffers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SpecialOffersScreen()),
    );
  }

  void _navigateToAllProfessionals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectBarberScreen()),
    );
  }

  void _navigateToAllAppointments() {
    // Navigate to all appointments screen
    showCustomSnackBar(context, 'All appointments screen will be implemented',
        type: SnackBarType.info);
  }

  void _navigateToQuickBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectBarberScreen()),
    );
  }

  void _viewBarberProfile(UserModel barber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarberProfileScreen(barber: barber),
      ),
    );
  }

  void _viewAppointmentDetails(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClientAppointmentDetailsScreen(appointment: appointment),
      ),
    );
  }

  void _showBarberQuickActions(UserModel barber) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _startChatWithBarber(barber);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Book Appointment'),
              onTap: () {
                Navigator.pop(context);
                _bookWithBarber(barber);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareBarberProfile(barber);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startChatWithBarber(UserModel barber) {
    // Navigate to chat with barber
    showCustomSnackBar(context, 'Chat functionality will be implemented',
        type: SnackBarType.info);
  }

  void _bookWithBarber(UserModel barber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServiceScreen(barber: barber),
      ),
    );
  }

  void _shareBarberProfile(UserModel barber) {
    showCustomSnackBar(context, 'Share functionality will be implemented',
        type: SnackBarType.info);
  }

  // Helper methods for status display
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
}
