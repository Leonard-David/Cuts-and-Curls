import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import 'select_service_screen.dart';
import '../../../shared/chat/chat_screen.dart';
import '../../../data/repositories/chat_repository.dart';
import 'package:sheersync/core/constants/colors.dart'; // ADD IMPORT

class SelectBarberScreen extends StatefulWidget {
  const SelectBarberScreen({super.key});

  @override
  State<SelectBarberScreen> createState() => _SelectBarberScreenState();
}

class _SelectBarberScreenState extends State<SelectBarberScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allBarbers = [];
  List<UserModel> _filteredBarbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
    _searchController.addListener(_filterBarbers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBarbers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', whereIn: ['barber', 'hairstylist']) // UPDATE: Include hairstylists
          .where('isOnline', isEqualTo: true)
          .get();

      setState(() {
        _allBarbers = querySnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return UserModel.fromMap(data);
            })
            .toList();
        _filteredBarbers = _allBarbers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading barbers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterBarbers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBarbers = _allBarbers.where((barber) {
        return barber.fullName.toLowerCase().contains(query) ||
            (barber.bio?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Barber'),
        backgroundColor: AppColors.background, // UPDATE: Use background color
        foregroundColor: AppColors.text, // UPDATE: Use text color
        elevation: 1,
      ),
      backgroundColor: AppColors.background, // UPDATE: Use background color
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight, // UPDATE: Use surface color
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
                  hintText: 'Search barbers...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary), // UPDATE: Use secondary text color
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          // Barbers List
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredBarbers.isEmpty
                    ? _buildEmptyState()
                    : _buildBarbersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary), // UPDATE: Use primary color
          const SizedBox(height: 16),
          Text(
            'Loading barbers...',
            style: TextStyle(color: AppColors.textSecondary), // UPDATE: Use secondary text color
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: AppColors.textSecondary), // UPDATE: Use secondary text color
          const SizedBox(height: 16),
          Text(
            'No barbers found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.text, // UPDATE: Use text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'No barbers are currently available'
                : 'No barbers match your search',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary), // UPDATE: Use secondary text color
          ),
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
      color: AppColors.surfaceLight, // UPDATE: Use surface color
      child: InkWell(
        onTap: () {
          _selectBarber(barber);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Barber Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                backgroundImage: barber.profileImage != null
                    ? NetworkImage(barber.profileImage!)
                    : null,
                child: barber.profileImage == null
                    ? Icon(Icons.person, size: 30, color: AppColors.textSecondary) // UPDATE: Use secondary text color
                    : null,
              ),
              const SizedBox(width: 16),
              // Barber Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.fullName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text, // UPDATE: Use text color
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.accent, size: 16), // UPDATE: Use accent color
                        const SizedBox(width: 4),
                        Text(
                          barber.rating?.toStringAsFixed(1) ?? '4.5',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          ' (${barber.totalRatings ?? 0})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary, // UPDATE: Use secondary text color
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Bio/Description
                    if (barber.bio != null) ...[
                      Text(
                        barber.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary, // UPDATE: Use secondary text color
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Status
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: barber.isOnline ? AppColors.success : AppColors.textSecondary, // UPDATE: Use theme colors
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          barber.isOnline ? 'Available Now' : 'Offline',
                          style: TextStyle(
                            color: barber.isOnline ? AppColors.success : AppColors.textSecondary, // UPDATE: Use theme colors
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Navigation Icon
              Icon(Icons.chevron_right, color: AppColors.textSecondary), // UPDATE: Use secondary text color
            ],
          ),
        ),
      ),
    );
  }

  void _selectBarber(UserModel barber) {
    if (!barber.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This barber is currently offline'),
          backgroundColor: AppColors.accent, // UPDATE: Use accent color
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background, // UPDATE: Use background color
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.cut, color: AppColors.primary), // UPDATE: Use primary color
                title: Text(
                  'Book Appointment',
                  style: TextStyle(color: AppColors.text), // UPDATE: Use text color
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectServiceScreen(barber: barber),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.chat, color: AppColors.success), // UPDATE: Use success color
                title: Text(
                  'Start Chat',
                  style: TextStyle(color: AppColors.text), // UPDATE: Use text color
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startChatWithBarber(barber);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startChatWithBarber(UserModel barber) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final client = authProvider.user!;
    final chatRepository = ChatRepository();

    try {
      final chatRoom = await chatRepository.getOrCreateChatRoom(
        clientId: client.id,
        clientName: client.fullName,
        barberId: barber.id,
        barberName: barber.fullName,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoom: chatRoom),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: AppColors.error, // UPDATE: Use error color
        ),
      );
    }
  }
}