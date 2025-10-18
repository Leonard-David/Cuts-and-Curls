import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/service_repository.dart';
import 'add_edit_service_screen.dart';

class BarberServicesScreen extends StatefulWidget {
  const BarberServicesScreen({super.key});

  @override
  State<BarberServicesScreen> createState() => _BarberServicesScreenState();
}

class _BarberServicesScreenState extends State<BarberServicesScreen> {
  final _serviceRepo = ServiceRepository();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _confirmDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _serviceRepo.deleteService(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a barber.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Services'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditServiceScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: _serviceRepo.getServicesForBarber(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No services added yet. Tap + to create one.'),
            );
          }

          final services = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      '${s.description}\n\$${s.price.toStringAsFixed(2)} • ${s.duration} min'),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditServiceScreen(service: s),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(s.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
