import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/data/models/service_model.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/repositories/service_repository.dart';
import 'package:sheersync/features/barber/profile/barber_profile_screen.dart';
import 'package:sheersync/features/client/bookings/confirm_booking_screen.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class SelectServiceScreen extends StatefulWidget {
  final UserModel barber;
  final ServiceModel? preselectedService;

  const SelectServiceScreen({
    super.key,
    required this.barber,
    this.preselectedService,
  });

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
    _selectedService = widget.preselectedService;
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      _serviceRepository.getBarberServicesForClient(widget.barber.id).listen(
        (services) {
          setState(() {
            _services = services;
            _isLoading = false;
          });
        },
        onError: (error) {
          print('Error loading services: $error');
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      print('Error loading services: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barber Header
                _buildBarberHeader(),
                const SizedBox(height: 16),
                // Services Count
                _buildServicesCount(),
                const SizedBox(height: 16),
                // Services List
                Expanded(
                  child: _services.isEmpty
                      ? _buildNoServices()
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: widget.barber.profileImage != null
                ? NetworkImage(widget.barber.profileImage!)
                : null,
            child: widget.barber.profileImage == null
                ? Icon(Icons.person, color: AppColors.textSecondary)
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.barber.isOnline
                            ? AppColors.success
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.barber.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: widget.barber.isOnline
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.star, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      widget.barber.rating?.toStringAsFixed(1) ?? '0.0',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Message Button
          _buildMessageButton(),
          const SizedBox(width: 8),
          // View Profile Button
          _buildViewProfileButton(),
        ],
      ),
    );
  }

  Widget _buildMessageButton() {
    return IconButton(
      onPressed: () => _startChatWithBarber(),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
      ),
      icon: Icon(
        Icons.message,
        size: 20,
        color: AppColors.primary,
      ),
      tooltip: 'Message ${widget.barber.fullName}',
    );
  }

  Widget _buildViewProfileButton() {
    return OutlinedButton(
      onPressed: () => _viewBarberProfile(),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'View Profile',
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  // Method to start chat with barber
  Future<void> _startChatWithBarber() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();

      if (authProvider.user == null) {
        _showErrorSnackBar('Please login to start a conversation');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get or create chat room
      final chatRoom = await chatProvider.getOrCreateChatRoom(
        clientId: authProvider.user!.id,
        clientName: authProvider.user!.fullName,
        barberId: widget.barber.id,
        barberName: widget.barber.fullName,
      );

      // Navigate to chat screen
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        _showErrorSnackBar('Failed to start conversation: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewBarberProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarberProfileScreen(barber: widget.barber),
      ),
    );
  }

  Widget _buildServicesCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_services.length} service${_services.length != 1 ? 's' : ''} available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
      color: isSelected
          ? AppColors.primary.withOpacity(0.05)
          : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide(color: AppColors.border),
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
              // Selection Indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              // Service Icon
              Container(
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
              const SizedBox(width: 16),
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (service.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.category!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Price and Duration
              Column(
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
                  const SizedBox(height: 4),
                  Text(
                    '${service.duration} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  Widget _buildNoServices() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Services Available',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.barber.fullName} hasn\'t added any services yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Add message button in empty state too
            ElevatedButton.icon(
              onPressed: () => _startChatWithBarber(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Message Professional'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _continueToBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _continueToBooking() {
    if (_selectedService != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmBookingScreen(
            barber: widget.barber,
            service: _selectedService!,
            selectedDateTime: DateTime.now(), // Will be selected in next screen
          ),
        ),
      );
    }
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
      case 'shaving':
        return Icons.face;
      case 'beard trim':
        return Icons.face_retouching_natural;
      case 'treatment':
        return Icons.spa;
      default:
        return Icons.construction;
    }
  }
}
