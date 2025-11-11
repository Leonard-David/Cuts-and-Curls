import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';

class SelectBarberScreen extends StatefulWidget {
  const SelectBarberScreen({super.key});

  @override
  State<SelectBarberScreen> createState() => _SelectBarberScreenState();
}

class _SelectBarberScreenState extends State<SelectBarberScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _allBarbers = [];
  List<UserModel> _filteredBarbers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBarbers();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadBarbers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', whereIn: ['barber', 'hairstylist'])
          .get();

      final barbers = querySnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data());
      }).toList();

      setState(() {
        _allBarbers = barbers;
        _filteredBarbers = barbers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading barbers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredBarbers = _allBarbers;
      } else {
        _filteredBarbers = _allBarbers.where((barber) {
          return barber.fullName.toLowerCase().contains(_searchQuery) ||
                 barber.userType.toLowerCase().contains(_searchQuery) ||
                 (barber.bio?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),
                // Results Count
                _buildResultsCount(),
                const SizedBox(height: 16),
                // Professionals List
                Expanded(
                  child: _filteredBarbers.isEmpty
                      ? _buildNoResults()
                      : _buildBarbersList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search barbers, hairstylists...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.background,
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredBarbers.length} professional${_filteredBarbers.length != 1 ? 's' : ''} found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Filter button could be added here
        ],
      ),
    );
  }

  Widget _buildBarbersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredBarbers.length,
      itemBuilder: (context, index) {
        final barber = _filteredBarbers[index];
        return _buildBarberCard(barber);
      },
    );
  }

  Widget _buildBarberCard(UserModel barber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _selectBarber(barber);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with Online Status
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: barber.profileImage != null
                        ? NetworkImage(barber.profileImage!)
                        : null,
                    child: barber.profileImage == null
                        ? Icon(Icons.person, size: 30, color: AppColors.textSecondary)
                        : null,
                  ),
                  // Online Status Indicator
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: barber.isOnline ? AppColors.success : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Barber Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: barber.userType == 'barber'
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        barber.userType == 'barber' ? 'Barber' : 'Hairstylist',
                        style: TextStyle(
                          fontSize: 12,
                          color: barber.userType == 'barber' 
                              ? AppColors.primary 
                              : AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          barber.rating?.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${barber.totalRatings ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (barber.bio != null && barber.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        barber.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Professionals Found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or check back later',
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

  void _selectBarber(UserModel barber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServiceScreen(barber: barber),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}