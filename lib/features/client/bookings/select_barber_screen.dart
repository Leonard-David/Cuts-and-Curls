import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import 'select_service_screen.dart';
import '../../../shared/chat/chat_screen.dart';
import '../../../data/repositories/chat_repository.dart';

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
          .where('userType', isEqualTo: 'barber')
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                decoration: const InputDecoration(
                  hintText: 'Search barbers...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading barbers...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No barbers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'No barbers are currently available'
                : 'No barbers match your search',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
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
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange.shade400, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          barber.rating?.toStringAsFixed(1) ?? '4.5',
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                    // Bio/Description
                    if (barber.bio != null) ...[
                      Text(
                        barber.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
                            color: barber.isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          barber.isOnline ? 'Available Now' : 'Offline',
                          style: TextStyle(
                            color: barber.isOnline ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Navigation Icon
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _selectBarber(UserModel barber) {
  if (!barber.isOnline) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This barber is currently offline'),
        backgroundColor: Colors.orange,
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
              leading: const Icon(Icons.cut, color: Colors.blue),
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
              leading: const Icon(Icons.chat, color: Colors.green),
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
        backgroundColor: Colors.red,
      ),
    );
  }
}
}