import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../features/auth/controllers/auth_provider.dart';
import '../bookings/select_barber_screen.dart';
import 'package:sheersync/core/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            
            const SizedBox(height: 24),
            
            // Search Bar
            _buildSearchBar(),
            
            const SizedBox(height: 24),
            
            // Featured Barbers - Real-time Stream
            _buildFeaturedBarbers(),
            
            const SizedBox(height: 24),
            
            // Promotions
            _buildPromotions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${user?.fullName.split(' ').first ?? 'there'}! 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find the perfect barber for your style',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search barbers, hairstylists...',
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          // Real-time search handled by stream
        },
      ),
    );
  }

  Widget _buildFeaturedBarbers() {
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
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectBarberScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Real-time barbers stream
        StreamBuilder<QuerySnapshot>(
          stream: _getBarbersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingBarbers();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final barbers = snapshot.data!.docs;
            final filteredBarbers = _filterBarbers(barbers);

            if (filteredBarbers.isEmpty) {
              return _buildNoResultsState();
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredBarbers.length,
              itemBuilder: (context, index) {
                final barberDoc = filteredBarbers[index];
                final barber = UserModel.fromMap(barberDoc.data() as Map<String, dynamic>);
                return _buildBarberCard(barber);
              },
            );
          },
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getBarbersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('userType', whereIn: ['barber', 'hairstylist'])
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterBarbers(List<QueryDocumentSnapshot> barbers) {
    if (!_isSearching) {
      return barbers.take(6).toList(); // Show only 6 barbers on home screen
    }

    final query = _searchController.text.toLowerCase();
    return barbers.where((barberDoc) {
      final barber = UserModel.fromMap(barberDoc.data() as Map<String, dynamic>);
      return barber.fullName.toLowerCase().contains(query) ||
          (barber.bio?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildBarberCard(UserModel barber) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _viewBarberProfile(barber);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barber Image with online status
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: barber.profileImage != null
                          ? NetworkImage(barber.profileImage!)
                          : null,
                      child: barber.profileImage == null
                          ? Icon(Icons.person, size: 30, color: AppColors.textSecondary)
                          : null,
                    ),
                  ),
                  // Online status indicator
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: barber.isOnline ? AppColors.success : AppColors.textSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Barber Name
              Text(
                barber.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Rating - Real-time from Firestore
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(barber.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final updatedBarber = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
                    return Row(
                      children: [
                        Icon(Icons.star, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          updatedBarber.rating?.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          ' (${updatedBarber.totalRatings ?? 0})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Icon(Icons.star, color: AppColors.accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        barber.rating?.toStringAsFixed(1) ?? '0.0',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              // User Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: barber.userType == 'barber' 
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  barber.userType == 'barber' ? 'Barber' : 'Hairstylist',
                  style: TextStyle(
                    fontSize: 10,
                    color: barber.userType == 'barber' ? AppColors.primary : AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewBarberProfile(UserModel barber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectBarberScreen(selectedBarber: barber),
      ),
    );
  }

  Widget _buildLoadingBarbers() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 60,
                  color: Colors.grey[200],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading barbers',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.person_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No barbers available',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later when professionals are online',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No matching barbers found',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Offer! 🎉',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get 20% off your first booking with any professional',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _bookWithPromotion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.accent,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  void _bookWithPromotion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectBarberScreen(),
      ),
    );
  }
}