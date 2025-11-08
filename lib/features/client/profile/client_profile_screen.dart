import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class ClientProfileScreen extends StatefulWidget {
  final UserModel user;

  const ClientProfileScreen({super.key, required this.user});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.user.fullName;
    _phoneController.text = widget.user.phone ?? '';
    _bioController.text = widget.user.bio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(authProvider),
                  const SizedBox(height: 24),

                  // Profile Information
                  _buildProfileInfo(),
                  const SizedBox(height: 24),

                  // Statistics
                  _buildStatistics(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Settings
                  _buildSettings(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: widget.user.profileImage != null
                    ? NetworkImage(widget.user.profileImage!)
                    : null,
                child: widget.user.profileImage == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and Email
          Text(
            widget.user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.email,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Member Since
          Text(
            'Member since ${DateFormat('MMM yyyy').format(widget.user.createdAt)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _toggleEditing,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isEditing ? AppColors.error : AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isEditing ? Icons.close : Icons.edit),
                    const SizedBox(width: 8),
                    Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                  ],
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Save'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio (Optional)',
                      prefixIcon: Icon(Icons.info),
                    ),
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('12', 'Appointments', Icons.calendar_today),
                _buildStatItem('8', 'Reviews', Icons.star),
                _buildStatItem('N\$450', 'Spent', Icons.payment),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionChip(
                  'Payment Methods',
                  Icons.payment,
                  _managePaymentMethods,
                ),
                _buildActionChip(
                  'Booking History',
                  Icons.history,
                  _viewBookingHistory,
                ),
                _buildActionChip(
                  'My Reviews',
                  Icons.reviews,
                  _viewMyReviews,
                ),
                _buildActionChip(
                  'Favorite Barbers',
                  Icons.favorite,
                  _viewFavorites,
                ),
                _buildActionChip(
                  'Notifications',
                  Icons.notifications,
                  _manageNotifications,
                ),
                _buildActionChip(
                  'Security',
                  Icons.security,
                  _securitySettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.primary),
    );
  }

  Widget _buildSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              'Privacy Settings',
              Icons.privacy_tip,
              _privacySettings,
            ),
            _buildSettingsItem(
              'Language & Region',
              Icons.language,
              _languageSettings,
            ),
            _buildSettingsItem(
              'Help & Support',
              Icons.help_outline,
              _helpSupport,
            ),
            _buildSettingsItem(
              'About App',
              Icons.info_outline,
              _aboutApp,
            ),
            _buildSettingsItem(
              'Logout',
              Icons.logout,
              _logout,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.text,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.text,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset form if cancelling edit
        _initializeForm();
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Update user profile
      final updatedUser = widget.user.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // In a real app, you would call the user repository to update the profile
      await Future.delayed(const Duration(seconds: 2));

      // Update auth provider
      authProvider.updateUserProfile(
        fullName: updatedUser.fullName,
        phone: updatedUser.phone,
        bio: updatedUser.bio,
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      showCustomSnackBar(
        context,
        'Profile updated successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      showCustomSnackBar(
        context,
        'Failed to update profile: $e',
        type: SnackBarType.error,
      );
    }
  }

  void _managePaymentMethods() {
    showCustomSnackBar(
      context,
      'Payment methods management will be implemented',
      type: SnackBarType.info,
    );
  }

  void _viewBookingHistory() {
    showCustomSnackBar(
      context,
      'Booking history will be implemented',
      type: SnackBarType.info,
    );
  }

  void _viewMyReviews() {
    showCustomSnackBar(
      context,
      'My reviews will be implemented',
      type: SnackBarType.info,
    );
  }

  void _viewFavorites() {
    showCustomSnackBar(
      context,
      'Favorite barbers will be implemented',
      type: SnackBarType.info,
    );
  }

  void _manageNotifications() {
    showCustomSnackBar(
      context,
      'Notification settings will be implemented',
      type: SnackBarType.info,
    );
  }

  void _securitySettings() {
    showCustomSnackBar(
      context,
      'Security settings will be implemented',
      type: SnackBarType.info,
    );
  }

  void _privacySettings() {
    showCustomSnackBar(
      context,
      'Privacy settings will be implemented',
      type: SnackBarType.info,
    );
  }

  void _languageSettings() {
    showCustomSnackBar(
      context,
      'Language settings will be implemented',
      type: SnackBarType.info,
    );
  }

  void _helpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For assistance, please contact our support team:\n\n'
          '📧 Email: support@sheersync.com\n'
          '📞 Phone: +1-555-HELP-NOW\n'
          '💬 Live Chat: Available 24/7\n\n'
          'We\'re here to help you with any questions or issues!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _aboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SheerSync'),
        content: const Text(
          'SheerSync v1.0.0\n\n'
          'Connect with professional barbers and hairstylists for your grooming needs. '
          'Book appointments, chat with professionals, and make secure payments all in one app.\n\n'
          '© 2024 SheerSync. All rights reserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmLogout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    final authProvider = context.read<AuthProvider>();
    authProvider.signOut();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
