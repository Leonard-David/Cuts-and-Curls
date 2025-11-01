import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/service_repository.dart';
import 'confirm_booking_screen.dart';

class SelectServiceScreen extends StatefulWidget {
  final UserModel barber;

  const SelectServiceScreen({super.key, required this.barber});

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {
  final ServiceRepository _serviceRepository = ServiceRepository();
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  ServiceModel? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      _serviceRepository
          .getBarberServicesForClient(widget.barber.id)
          .listen((services) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Error loading services: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Service'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barber Info Header
          _buildBarberHeader(),
          const SizedBox(height: 16),
          // Services List
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _services.isEmpty
                    ? _buildEmptyState()
                    : _buildServicesList(),
          ),
          // Continue Button
          if (_selectedService != null) _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildBarberHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: widget.barber.profileImage != null
                ? NetworkImage(widget.barber.profileImage!)
                : null,
            child: widget.barber.profileImage == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.barber.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange.shade400, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.barber.rating?.toStringAsFixed(1) ?? '4.5',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
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
          Text('Loading services...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Services Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This barber hasn\'t added any services yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    final isSelected = _selectedService?.id == service.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedService = service;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Service Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getServiceIcon(service.category),
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${service.duration} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'N\$${service.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_selectedService != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfirmBookingScreen(
                  barber: widget.barber,
                  service: _selectedService!,
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue to Booking',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'haircut':
        return Icons.cut;
      case 'coloring':
        return Icons.color_lens;
      case 'styling':
        return Icons.style;
      case 'washing':
        return Icons.wash;
      default:
        return Icons.face;
    }
  }
}