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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _availableBarbers = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<Map<String, dynamic>> _recentActivities = [];
  List<MarketingOffer> _activeOffers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRealTimeData();
  }

  void _initializeRealTimeData() {
    _loadAvailableBarbers();
    _loadUpcomingAppointments();
    _loadRecentActivities();
  }

  Stream<List<UserModel>> _getAvailableBarbersStream() {
    return _firestore
        .collection('users')
        .where('userType', whereIn: ['barber', 'hairstylist'])
        .where('isOnline', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  void _loadAvailableBarbers() {
    _getAvailableBarbersStream().listen((barbers) {
      if (mounted) {
        setState(() {
          _availableBarbers = barbers;
          _isLoading =
              _upcomingAppointments.isEmpty && _recentActivities.isEmpty;
        });
      }
    }, onError: (error) {
      print('Error loading barbers: $error');
    });
  }

  void _loadUpcomingAppointments() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: authProvider.user!.id)
        .where('status', whereIn: ['pending', 'confirmed'])
        .where('date',
            isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch)
        .orderBy('date', descending: false)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _upcomingAppointments = snapshot.docs
                  .map((doc) => AppointmentModel.fromMap(doc.data()))
                  .toList();
              _isLoading =
                  _availableBarbers.isEmpty && _recentActivities.isEmpty;
            });
          }
        }, onError: (error) {
          print('Error loading appointments: $error');
        });
  }

  void _loadRecentActivities() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: authProvider.user!.id)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _recentActivities = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoading =
              _availableBarbers.isEmpty && _upcomingAppointments.isEmpty;
        });
      }
    }, onError: (error) {
      print('Error loading activities: $error');
    });
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

            // Special Offers
            _buildSpecialOffersSection(),
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
                const SizedBox(height: 8),
                // Quick stats
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.calendar_today,
                      value: _upcomingAppointments.length.toString(),
                      label: 'Upcoming',
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.star,
                      value: authProvider.user?.totalRatings?.toString() ?? '0',
                      label: 'Reviews',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
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
                icon: Icons.calendar_today_rounded,
                title: 'Book Appointment',
                subtitle: 'Schedule your visit',
                color: Colors.green,
                onTap: _navigateToQuickBooking,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.local_offer_rounded,
                title: 'Special Offers',
                subtitle: 'View discounts & deals',
                color: AppColors.accent,
                onTap: _navigateToOffers,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.star_rounded,
                title: 'My Reviews',
                subtitle: 'See your ratings',
                color: Colors.purple,
                onTap: _navigateToReviews,
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
    final hasDiscount = _checkBarberHasDiscount(barber.id);

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
              // Discount Badge
              if (hasDiscount)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkBarberHasDiscount(String barberId) {
    return _activeOffers.any((offer) => offer.barberId == barberId);
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

  Widget _buildSpecialOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Offers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        _activeOffers.isEmpty
            ? _buildNoOffersAvailable()
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _activeOffers.length,
                  itemBuilder: (context, index) {
                    final offer = _activeOffers[index];
                    return _buildOfferCard(offer);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildOfferCard(MarketingOffer offer) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        color: AppColors.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _viewOfferDetails(offer),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_offer,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use code: ${offer.discountCode}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${offer.discount}% OFF',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildNoOffersAvailable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No Current Offers',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for special promotions and discounts',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
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

  void _navigateToQuickBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectBarberScreen()),
    );
  }

  void _navigateToOffers() {
    // Navigate to offers screen
    showCustomSnackBar(context, 'Offers screen will be implemented',
        type: SnackBarType.info);
  }

  void _navigateToReviews() {
    // Navigate to reviews screen
    showCustomSnackBar(context, 'Reviews screen will be implemented',
        type: SnackBarType.info);
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

  void _viewOfferDetails(MarketingOffer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offer.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offer.description),
            const SizedBox(height: 12),
            Text(
              'Discount: ${offer.discount}%',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Code: ${offer.discountCode}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Valid until: ${DateFormat('MMM d, yyyy').format(offer.expiresAt)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useOffer(offer);
            },
            child: const Text('Use Offer'),
          ),
        ],
      ),
    );
  }

  void _useOffer(MarketingOffer offer) {
    showCustomSnackBar(
      context,
      'Offer code ${offer.discountCode} copied to clipboard',
      type: SnackBarType.success,
    );
    // In a real app, you would copy to clipboard and navigate to booking
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

// Marketing Offer Model
class MarketingOffer {
  final String id;
  final String title;
  final String description;
  final int discount;
  final String discountCode;
  final String barberId;
  final DateTime expiresAt;
  final bool isActive;

  MarketingOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.discountCode,
    required this.barberId,
    required this.expiresAt,
    required this.isActive,
  });

  factory MarketingOffer.fromMap(Map<String, dynamic> map) {
    return MarketingOffer(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      discount: map['discount'],
      discountCode: map['discountCode'],
      barberId: map['barberId'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt']),
      isActive: map['isActive'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discount': discount,
      'discountCode': discountCode,
      'barberId': barberId,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }
}
