import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profileImage != null
                          ? NetworkImage(user!.profileImage!)
                          : null,
                      child: user?.profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue.shade600,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'Client',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Client',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              
              // Quick Stats Section
              _buildQuickStatsSection(),
              const SizedBox(height: 24),
              
              // Profile Actions Section
              _buildProfileActionsSection(context),
              const SizedBox(height: 24),
              
              // App Features Section
              _buildAppFeaturesSection(context),
              const SizedBox(height: 24),
              
              // Support Section
              _buildSupportSection(context),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('12', 'Bookings', Icons.calendar_today),
              _buildStatItem('8', 'Completed', Icons.check_circle),
              _buildStatItem('4.8', 'Rating', Icons.star),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Profile Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildProfileActionItem(
              icon: Icons.edit,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () => _editProfile(context),
            ),
            _buildProfileActionItem(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              subtitle: 'Manage your payment options',
              onTap: () => _managePayments(context),
            ),
            _buildProfileActionItem(
              icon: Icons.favorite,
              title: 'Favorite Barbers',
              subtitle: 'View your preferred barbers',
              onTap: () => _viewFavorites(context),
            ),
            _buildProfileActionItem(
              icon: Icons.history,
              title: 'Booking History',
              subtitle: 'View your past appointments',
              onTap: () => _viewHistory(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppFeaturesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'App Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildFeatureItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () => _manageNotifications(context),
            ),
            _buildFeatureItem(
              icon: Icons.security,
              title: 'Privacy & Security',
              subtitle: 'Control your privacy settings',
              onTap: () => _privacySettings(context),
            ),
            _buildFeatureItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help using the app',
              onTap: () => _helpSupport(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSupportItem(
              icon: Icons.contact_support,
              title: 'Contact Support',
              onTap: () => _contactSupport(context),
            ),
            _buildSupportItem(
              icon: Icons.feedback,
              title: 'Send Feedback',
              onTap: () => _sendFeedback(context),
            ),
            _buildSupportItem(
              icon: Icons.star,
              title: 'Rate Our App',
              onTap: () => _rateApp(context),
            ),
            _buildSupportItem(
              icon: Icons.share,
              title: 'Share App',
              onTap: () => _shareApp(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue.shade600, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.green.shade600, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.orange.shade600, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Action Methods
  void _editProfile(BuildContext context) {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon')),
    );
  }

  void _managePayments(BuildContext context) {
     ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Payment management feature coming soon'),
      duration: Duration(seconds: 2),
    ),
  );
  }

  void _viewFavorites(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorite barbers feature coming soon')),
    );
  }

  void _viewHistory(BuildContext context) {
    // This would navigate to a detailed booking history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking history feature coming soon')),
    );
  }

  void _manageNotifications(BuildContext context) {
    // Navigate to notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings feature coming soon')),
    );
  }

  void _privacySettings(BuildContext context) {
    // Navigate to privacy settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings feature coming soon')),
    );
  }

  void _helpSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support feature coming soon')),
    );
  }

  void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support feature coming soon')),
    );
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send feedback feature coming soon')),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate app feature coming soon')),
    );
  }

  void _shareApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share app feature coming soon')),
    );
  }
}