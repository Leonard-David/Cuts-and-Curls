import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../features/auth/controllers/auth_provider.dart';
import '../bookings/select_barber_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _featuredBarbers = [];

  @override
  void initState() {
    super.initState();
    _loadFeaturedBarbers();
  }

  Future<void> _loadFeaturedBarbers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'barber')
          .where('isOnline', isEqualTo: true)
          .limit(6)
          .get();

      setState(() {
        _featuredBarbers = querySnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return UserModel.fromMap(data);
            })
            .toList();
      });
    } catch (e) {
      print('Error loading barbers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            
            // Quick Services
            _buildQuickServices(),
            
            const SizedBox(height: 24),
            
            // Featured Barbers
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find the perfect barber for your style',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          hintText: 'Search barbers, services...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          // Implement search functionality
        },
      ),
    );
  }

  Widget _buildQuickServices() {
    final List<Map<String, dynamic>> services = [
      {'icon': Icons.cut, 'name': 'Haircut', 'color': Colors.blue},
      {'icon': Icons.wash, 'name': 'Wash & Style', 'color': Colors.green},
      {'icon': Icons.color_lens, 'name': 'Coloring', 'color': Colors.orange},
      {'icon': Icons.style, 'name': 'Styling', 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                width: 80,
                margin: EdgeInsets.only(right: index == services.length - 1 ? 0 : 12),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: service['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        service['icon'],
                        color: service['color'],
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBarbers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Barbers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _featuredBarbers.isEmpty
            ? _buildLoadingBarbers()
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _featuredBarbers.length,
                itemBuilder: (context, index) {
                  final barber = _featuredBarbers[index];
                  return _buildBarberCard(barber);
                },
              ),
      ],
    );
  }

  Widget _buildBarberCard(UserModel barber) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to barber profile
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barber Image
              Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: barber.profileImage != null
                      ? NetworkImage(barber.profileImage!)
                      : null,
                  child: barber.profileImage == null
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
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
              // Rating
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orange.shade400, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    barber.rating?.toStringAsFixed(1) ?? '4.5',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    ' (${barber.totalRatings ?? 0})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: barber.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    barber.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: barber.isOnline ? Colors.green : Colors.grey,
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

  Widget _buildPromotions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade600, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Offer!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get 20% off your first booking with any barber',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to booking
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }
}