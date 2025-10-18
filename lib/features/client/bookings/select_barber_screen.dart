import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart'; 
import 'select_service_screen.dart'; // next screen

class SelectBarberScreen extends StatefulWidget {
  const SelectBarberScreen({super.key});

  @override
  State<SelectBarberScreen> createState() => _SelectBarberScreenState();
}

class _SelectBarberScreenState extends State<SelectBarberScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _barberStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'barber')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Select a Barber'),
      ),
      body: Column(
        children: [
          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search barbers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // 🔹 Barber List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _barberStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No barbers found.'));
                }

                // Filter by search query
                final filteredBarbers = snapshot.data!.docs.where((doc) {
                  final name = (doc.data()['displayName'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredBarbers.isEmpty) {
                  return const Center(child: Text('No barbers match your search.'));
                }

                return ListView.builder(
                  itemCount: filteredBarbers.length,
                  itemBuilder: (context, index) {
                    final barber = filteredBarbers[index].data();
                    final barberId = filteredBarbers[index].id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectServiceScreen(barberId: barberId, barberData: barber),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Profile Image
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: barber['profileImage'] != null
                                    ? NetworkImage(barber['profileImage'])
                                    : const AssetImage('lib/assets/images/icon/icon.png') as ImageProvider,
                              ),
                              const SizedBox(width: 16),

                              // Barber Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      barber['displayName'] ?? 'Unknown Barber',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      barber['bio'] ?? 'No bio provided',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Rating (optional)
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              Text(
                                (barber['rating'] ?? '4.8').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
