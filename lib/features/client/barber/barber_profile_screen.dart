import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/models/review_model.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/repositories/availability_repository.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';

class BarberProfileScreen extends StatefulWidget {
  final UserModel barber;

  const BarberProfileScreen({super.key, required this.barber});

  @override
  State<BarberProfileScreen> createState() => _BarberProfileScreenState();
}

class _BarberProfileScreenState extends State<BarberProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AvailabilityRepository _availabilityRepository =
      AvailabilityRepository();

  List<ServiceModel> _services = [];
  List<ReviewModel> _reviews = [];
  List<Map<String, dynamic>> _discounts = [];
  Map<String, dynamic> _availability = {};
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>>? _availabilitySubscription;

  @override
  void initState() {
    super.initState();
    _loadBarberData();
    _setupRealTimeAvailability();
  }

  @override
  void dispose() {
    _availabilitySubscription?.cancel();
    super.dispose();
  }

  void _setupRealTimeAvailability() {
    _availabilitySubscription = _availabilityRepository
        .getAvailabilityStream(widget.barber.id)
        .listen((availability) {
      if (mounted) {
        setState(() {
          _availability = availability;
        });
      }
    }, onError: (error) {
      print('Error in availability stream: $error');
    });
  }

  Future<void> _loadBarberData() async {
    try {
      // Load services
      final servicesSnapshot = await _firestore
          .collection('services')
          .where('barberId', isEqualTo: widget.barber.id)
          .where('isActive', isEqualTo: true)
          .get();

      _services = servicesSnapshot.docs.map((doc) {
        return ServiceModel.fromMap(doc.data());
      }).toList();

      // Load reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('barberId', isEqualTo: widget.barber.id)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _reviews = reviewsSnapshot.docs.map((doc) {
        return ReviewModel.fromMap(doc.data());
      }).toList();

      // Calculate average rating
      if (_reviews.isNotEmpty) {
        _averageRating =
            _reviews.map((review) => review.rating).reduce((a, b) => a + b) /
                _reviews.length;
        _totalReviews = _reviews.length;
      }

      // Load discounts
      final discountsSnapshot = await _firestore
          .collection('discounts')
          .where('barberId', isEqualTo: widget.barber.id)
          .where('isActive', isEqualTo: true)
          .where('expiresAt',
              isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .get();

      _discounts = discountsSnapshot.docs.map((doc) => doc.data()).toList();

      // Load initial availability
      _availability =
          await _availabilityRepository.getAvailability(widget.barber.id);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading barber data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar with Barber Info
                _buildAppBar(),
                // Main Content
                SliverList(
                  delegate: SliverChildListDelegate([
                    // Services Section
                    _buildServicesSection(),
                    // Availability Section
                    if (_availability.isNotEmpty) _buildAvailabilitySection(),
                    // Discounts Section
                    if (_discounts.isNotEmpty) _buildDiscountsSection(),
                    // Reviews Section
                    _buildReviewsSection(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            // Barber Info Overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Barber Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: widget.barber.profileImage != null
                            ? NetworkImage(widget.barber.profileImage!)
                            : null,
                        child: widget.barber.profileImage == null
                            ? Icon(Icons.person,
                                size: 40, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Barber Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.barber.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.barber.userType == 'barber'
                                  ? 'Professional Barber'
                                  : 'Hairstylist',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Rating and Online Status
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: widget.barber.isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.barber.isOnline ? 'Online' : 'Offline',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  _averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($_totalReviews reviews)',
                                  style: const TextStyle(
                                    color: Colors.white70,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_services.isEmpty)
                Text(
                  'No services available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Column(
                  children: _services
                      .map((service) => _buildServiceItem(service))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(ServiceModel service) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cut, color: AppColors.primary),
      ),
      title: Text(
        service.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(service.description),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'N\$${service.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(
            '${service.duration} min',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final isCurrentlyAvailable =
        _availabilityRepository.isCurrentlyAvailable(_availability);
    final todayAvailability =
        _availabilityRepository.getTodaysAvailability(_availability);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAvailabilitySchedule(),
                  const Spacer(),
                  // Current status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentlyAvailable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isCurrentlyAvailable ? Colors.green : Colors.grey,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCurrentlyAvailable
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCurrentlyAvailable
                              ? 'Available Now'
                              : 'Currently Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isCurrentlyAvailable
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Today's availability
              if (todayAvailability['isAvailable'])
                _buildTodaysAvailability(todayAvailability),

              // Weekly schedule
              _buildWeeklySchedule(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final days = [
      {'key': 'monday', 'name': 'Monday'},
      {'key': 'tuesday', 'name': 'Tuesday'},
      {'key': 'wednesday', 'name': 'Wednesday'},
      {'key': 'thursday', 'name': 'Thursday'},
      {'key': 'friday', 'name': 'Friday'},
      {'key': 'saturday', 'name': 'Saturday'},
      {'key': 'sunday', 'name': 'Sunday'},
    ];

    return Column(
      children: days.map((day) {
        final dayData =
            _availability[day['key']] ?? {'isAvailable': false, 'slots': []};
        final isAvailable = dayData['isAvailable'] == true;
        final slots = List<Map<String, dynamic>>.from(dayData['slots'] ?? []);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  day['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        isAvailable ? AppColors.text : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isAvailable
                    ? slots.isEmpty
                        ? Text(
                            'Available all day',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: slots.map((slot) {
                              return Text(
                                '${slot['start']}-${slot['end']}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          )
                    : Text(
                        'Not available',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodaysAvailability(Map<String, dynamic> todayAvailability) {
    final slots =
        List<Map<String, dynamic>>.from(todayAvailability['slots'] ?? []);
    final dayName = _capitalizeFirstLetter(todayAvailability['day'].toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today ($dayName)',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (slots.isEmpty)
          Text(
            'Available all day',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: slots.map((slot) {
              return Chip(
                label: Text(
                  '${slot['start']} - ${slot['end']}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: TextStyle(color: AppColors.primary),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildAvailabilitySchedule() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: days.map((day) {
        final dayAvailability = _availability[day.toLowerCase()];
        final isAvailable =
            dayAvailability != null && dayAvailability['isAvailable'] == true;
        final slots = dayAvailability?['slots'] ?? [];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: 60,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isAvailable ? AppColors.text : AppColors.textSecondary,
              ),
            ),
          ),
          title: isAvailable && slots.isNotEmpty
              ? Text(
                  slots
                      .map((slot) => '${slot['start']} - ${slot['end']}')
                      .join(', '),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                )
              : Text(
                  isAvailable ? 'Available' : 'Not Available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
          trailing: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscountsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._discounts
                  .map((discount) => _buildDiscountItem(discount))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountItem(Map<String, dynamic> discount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.accent.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.local_offer, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discount['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    discount['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${discount['code']} • ${discount['discount']}% OFF',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
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

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_reviews.isEmpty)
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Column(
                  children: _reviews
                      .take(3)
                      .map((review) => _buildReviewItem(review))
                      .toList(),
                ),
              if (_reviews.length > 3) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _viewAllReviews,
                    child: const Text('View All Reviews'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rating Stars
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                );
              }),
              const SizedBox(width: 8),
              Text(
                review.clientName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _startChat,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColors.primary),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 18),
                  SizedBox(width: 8),
                  Text('Message'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _bookAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18),
                  SizedBox(width: 8),
                  Text('Book Now'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startChat() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.user == null) {
      showCustomSnackBar(context, 'Please login to start chatting',
          type: SnackBarType.error);
      return;
    }

    try {
      // Create or get chat room
      final chatRoom = await chatProvider.getOrCreateChatRoom(
        clientId: authProvider.user!.id,
        clientName: authProvider.user!.fullName,
        barberId: widget.barber.id,
        barberName: widget.barber.fullName,
      );

      // Navigate to chat screen
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

  void _bookAppointment() {
    if (_services.isEmpty) {
      showCustomSnackBar(
        context,
        'This professional has no available services',
        type: SnackBarType.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServiceScreen(barber: widget.barber),
      ),
    );
  }

  void _viewAllReviews() {
    // Navigate to full reviews screen
    showCustomSnackBar(
      context,
      'All reviews screen will be implemented',
      type: SnackBarType.info,
    );
  }
}
