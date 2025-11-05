import 'package:flutter/material.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/repositories/service_repository.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';

class BarberProfileScreen extends StatefulWidget {
  final UserModel barber;

  const BarberProfileScreen({super.key, required this.barber});

  @override
  State<BarberProfileScreen> createState() => _BarberProfileScreenState();
}

class _BarberProfileScreenState extends State<BarberProfileScreen> {
  final ServiceRepository _serviceRepository = ServiceRepository();
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarberServices();
  }

  Future<void> _loadBarberServices() async {
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
      print('Error loading barber services: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barber Header Section
          _buildBarberHeader(),
          const SizedBox(height: 24),
          // About Section
          _buildAboutSection(),
          const SizedBox(height: 24),
          // Services Section
          _buildServicesSection(),
          const SizedBox(height: 24),
          // Reviews Section
          _buildReviewsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBarberHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Barber Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.barber.profileImage != null
                      ? NetworkImage(widget.barber.profileImage!)
                      : null,
                  child: widget.barber.profileImage == null
                      ? Icon(Icons.person, size: 40, color: AppColors.textSecondary)
                      : null,
                ),
                // Online Status
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: widget.barber.isOnline ? AppColors.success : AppColors.textSecondary,
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
                    widget.barber.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.barber.userType == 'barber'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.barber.userType == 'barber' ? 'Professional Barber' : 'Hairstylist',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.barber.userType == 'barber' ? AppColors.primary : AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating and Reviews
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.accent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        widget.barber.rating?.toStringAsFixed(1) ?? '0.0',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.barber.totalRatings ?? 0} reviews)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                          color: widget.barber.isOnline ? AppColors.success : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.barber.isOnline ? 'Available Now' : 'Currently Offline',
                        style: TextStyle(
                          color: widget.barber.isOnline ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.barber.bio ?? 'No bio available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? _buildNoServices()
                    : _buildServicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServices() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.style, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No Services Available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This professional hasn\'t added any services yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: _services.map((service) => _buildServiceItem(service)).toList(),
    );
  }

  Widget _buildServiceItem(ServiceModel service) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getServiceIcon(service.category),
          color: AppColors.primary,
        ),
      ),
      title: Text(
        service.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        service.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'N\$${service.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(
            '${service.duration} min',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      onTap: () {
        _bookService(service);
      },
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reviews & Ratings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Reviews summary
            _buildReviewsSummary(),
            const SizedBox(height: 16),
            // Placeholder for individual reviews
            _buildReviewsPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rating Circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.barber.rating?.toStringAsFixed(1) ?? '0.0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.star, color: Colors.white, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.barber.totalRatings ?? 0} Reviews',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Star distribution would go here
                Text(
                  'Based on customer feedback',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.reviews, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Customer Reviews',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews from satisfied customers will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _bookService(ServiceModel service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServiceScreen(
          barber: widget.barber,
          preselectedService: service,
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