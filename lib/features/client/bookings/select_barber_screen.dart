import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/core/constants/colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Professional'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
              ),
            ),
          ),
          // Real-time Professionals List
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
                    final barberData = barberDoc.data() as Map<String, dynamic>;
                    final barber = UserModel.fromMap(barberData);
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
      final barberData = barberDoc.data() as Map<String, dynamic>;
      final barber = UserModel.fromMap(barberData);
      return barber.fullName.toLowerCase().contains(query) ||
          (barber.bio?.toLowerCase().contains(query) ?? false) ||
          barber.userType.toLowerCase().contains(query);
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading professionals',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Professionals Available',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later when professionals join the platform',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No matching professionals found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
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
                        ? Icon(Icons.person, size: 30, color: AppColors.textSecondary)
                        : null,
                  ),
                  // Online Status Indicator
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
                          final updatedData = snapshot.data!.data() as Map<String, dynamic>;
                          final updatedBarber = UserModel.fromMap(updatedData);
                          return Row(
                            children: [
                              Icon(Icons.star, color: AppColors.accent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                updatedBarber.rating?.toStringAsFixed(1) ?? '0.0',
                                style: const TextStyle(fontWeight: FontWeight.w500),
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
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Real-time Status
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(barber.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final isOnline = snapshot.hasData 
                            ? (snapshot.data!.data() as Map<String, dynamic>)['isOnline'] ?? false
                            : barber.isOnline;
                            
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? AppColors.success : AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Available Now' : 'Offline',
                              style: TextStyle(
                                color: isOnline ? AppColors.success : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Navigation Icon
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _selectBarber(UserModel barber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              barber.userType == 'barber' ? 'Professional Barber' : 'Hairstylist',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Options
                ListTile(
                  leading: Icon(Icons.calendar_today, color: AppColors.primary),
                  title: const Text('Book Appointment'),
                  subtitle: Text(
                    barber.isOnline 
                        ? 'Schedule a service with ${barber.fullName}'
                        : '${barber.fullName} is currently offline',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (barber.isOnline) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectServiceScreen(barber: barber),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${barber.fullName} is currently offline and cannot accept bookings'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: AppColors.success),
                  title: const Text('Start Chat'),
                  subtitle: const Text('Send a message to this professional'),
                  onTap: () {
                    Navigator.pop(context);
                    _startChatWithBarber(barber);
                  },
                ),
                // Cancel Button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}