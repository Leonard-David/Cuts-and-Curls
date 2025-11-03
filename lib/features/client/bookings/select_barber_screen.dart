import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/core/constants/colors.dart'; // ADD THIS
import '../../../data/models/user_model.dart';
import 'select_service_screen.dart';
import '../../../shared/chat/chat_screen.dart';
import '../../../data/repositories/chat_repository.dart';

class SelectBarberScreen extends StatefulWidget {
  final UserModel? selectedBarber;
  
  const SelectBarberScreen({super.key, this.selectedBarber});

  @override
  State<SelectBarberScreen> createState() => _SelectBarberScreenState();
}

class _SelectBarberScreenState extends State<SelectBarberScreen> {
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
      backgroundColor: AppColors.background, // UPDATE: Use theme background
      appBar: AppBar(
        title: const Text('Select Professional'),
        backgroundColor: AppColors.primary, // UPDATE: Use primary color
        foregroundColor: AppColors.onPrimary, // UPDATE: Use onPrimary color
        elevation: 1,
      ),
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
                  hintText: 'Search barbers, hairstylists...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary), // UPDATE: Use secondary text color
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textSecondary), // UPDATE: Use secondary text color
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          // Barbers List - Real-time Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', whereIn: ['barber', 'hairstylist'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredBarbers.length,
                  itemBuilder: (context, index) {
                    final barberDoc = filteredBarbers[index];
                    final barber = UserModel.fromMap(barberDoc.data() as Map<String, dynamic>);
                    return _buildBarberCard(barber);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterBarbers(List<QueryDocumentSnapshot> barbers) {
    if (!_isSearching) {
      return barbers;
    }

    final query = _searchController.text.toLowerCase();
    return barbers.where((barberDoc) {
      final barber = UserModel.fromMap(barberDoc.data() as Map<String, dynamic>);
      return barber.fullName.toLowerCase().contains(query) ||
          (barber.bio?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading professionals...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error), // UPDATE: Use error color
          const SizedBox(height: 16),
          Text(
            'Error loading professionals',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold), // UPDATE: Use error color
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
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
            'No professionals found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary, // UPDATE: Use secondary text color
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later when professionals are available',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary), // UPDATE: Use secondary text color
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary), // UPDATE: Use secondary text color
          const SizedBox(height: 16),
          Text(
            'No matching professionals found',
            style: TextStyle(
              color: AppColors.textSecondary, // UPDATE: Use secondary text color
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary), // UPDATE: Use secondary text color
          ),
        ],
      ),
    );
  }

  Widget _buildBarberCard(UserModel barber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _selectBarber(barber);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Barber Avatar with Online Status
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
                        ? Icon(Icons.person, size: 30, color: AppColors.textSecondary) // UPDATE: Use secondary text color
                        : null,
                  ),
                  // Online Status Indicator
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: barber.isOnline ? AppColors.success : AppColors.textSecondary, // UPDATE: Use theme colors
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2), // UPDATE: Use background color
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Real-time Rating Stream
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
                              Icon(Icons.star, color: AppColors.accent, size: 16), // UPDATE: Use accent color
                              const SizedBox(width: 4),
                              Text(
                                updatedBarber.rating?.toStringAsFixed(1) ?? '0.0',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                ' (${updatedBarber.totalRatings ?? 0})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary, // UPDATE: Use secondary text color
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Icon(Icons.star, color: AppColors.accent, size: 16), // UPDATE: Use accent color
                            const SizedBox(width: 4),
                            Text(
                              barber.rating?.toStringAsFixed(1) ?? '0.0',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    // Professional Type
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
          content: Text('${barber.fullName} is currently offline'),
          backgroundColor: AppColors.accent, // UPDATE: Use accent color
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.cut, color: AppColors.primary), // UPDATE: Use primary color
                title: const Text('Book Appointment'),
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
                title: const Text('Start Chat'),
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