import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';

class SpecialOffersScreen extends StatefulWidget {
  const SpecialOffersScreen({super.key});

  @override
  State<SpecialOffersScreen> createState() => _SpecialOffersScreenState();
}

class _SpecialOffersScreenState extends State<SpecialOffersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _activeOffers = [];
  Map<String, UserModel> _barberCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveOffers();
  }

  void _loadActiveOffers() {
    _firestore
        .collection('marketing_offers')
        .where('isActive', isEqualTo: true)
        .where('expiresAt',
            isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .listen((snapshot) async {
      final offers = snapshot.docs.map((doc) => doc.data()).toList();

      // Load barber information for each offer
      for (final offer in offers) {
        final barberId = offer['barberId'];
        if (barberId != null && !_barberCache.containsKey(barberId)) {
          final barber = await _getBarberInfo(barberId);
          if (barber != null) {
            _barberCache[barberId] = barber;
          }
        }
      }

      if (mounted) {
        setState(() {
          _activeOffers = offers;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('Error loading offers: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<UserModel?> _getBarberInfo(String barberId) async {
    try {
      final doc = await _firestore.collection('users').doc(barberId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return UserModel.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting barber info: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REMOVED: appBar: AppBar(...),
      body: _isLoading
          ? _buildLoadingState()
          : _activeOffers.isEmpty
              ? _buildEmptyState()
              : _buildOffersList(),
    );
  }

  // ... rest of the methods remain exactly the same
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Special Offers Available',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new promotions and discounts',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOffers.length,
      itemBuilder: (context, index) {
        final offer = _activeOffers[index];
        final barber = _barberCache[offer['barberId']];
        return _buildOfferCard(offer, barber);
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, UserModel? barber) {
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(offer['expiresAt']);
    final daysUntilExpiry = expiresAt.difference(DateTime.now()).inDays;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barber Info
            if (barber != null) _buildBarberInfo(barber),

            // Offer Details
            const SizedBox(height: 12),
            Text(
              offer['title'] ?? 'Special Offer',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              offer['description'] ?? '',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            // Discount and Code
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${offer['discount']}% OFF',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Code: ${offer['discountCode']}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Expiry Info
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${DateFormat('MMM d, yyyy').format(expiresAt)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysUntilExpiry <= 3
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysUntilExpiry <= 3 ? 'Ending soon' : 'Active',
                    style: TextStyle(
                      color:
                          daysUntilExpiry <= 3 ? Colors.orange : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Use Offer Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _useOffer(offer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Use This Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarberInfo(UserModel barber) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: barber.profileImage != null
              ? NetworkImage(barber.profileImage!)
              : null,
          child: barber.profileImage == null
              ? Icon(Icons.person, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                barber.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                barber.userType == 'barber'
                    ? 'Professional Barber'
                    : 'Hairstylist',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: barber.isOnline ? AppColors.success : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          barber.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _useOffer(Map<String, dynamic> offer) {
    // Copy code to clipboard and navigate to booking
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offer Code Copied'),
        content: Text(
          'The discount code "${offer['discountCode']}" has been copied to clipboard. '
          'You can use it when booking with ${_barberCache[offer['barberId']]?.fullName ?? 'the professional'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to booking with this barber
              _bookWithBarber(offer['barberId']);
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  void _bookWithBarber(String barberId) {
    final barber = _barberCache[barberId];
    if (barber != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SelectServiceScreen(barber: barber),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redirecting to book with ${barber.fullName}'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barber information not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
