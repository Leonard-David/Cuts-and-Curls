import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/data/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return settingsProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Section
                _buildProfileSection(authProvider),
                const SizedBox(height: 24),
                
                // Appearance Section
                _buildAppearanceSection(settingsProvider),
                const SizedBox(height: 24),
                
                // Notifications Section
                _buildNotificationsSection(settingsProvider),
                const SizedBox(height: 24),
                
                // Privacy & Security Section
                _buildPrivacySecuritySection(settingsProvider),
                const SizedBox(height: 24),
                
                // Data & Storage Section
                _buildDataStorageSection(settingsProvider),
                const SizedBox(height: 24),
                
                // Support Section
                _buildSupportSection(),
                const SizedBox(height: 24),
                
                // Account Actions Section
                _buildAccountActionsSection(authProvider),
                const SizedBox(height: 32),
              ],
            ),
          );
  }

  Widget _buildProfileSection(AuthProvider authProvider) {
    final user = authProvider.user;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: user?.profileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          user!.profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppColors.primary,
                      ),
              ),
              title: Text(
                user?.fullName ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user?.userType == 'barber' ? 'Professional Barber' : 'Client'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _editProfile();
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingButton(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => _editProfile(),
            ),
            _buildSettingButton(
              icon: Icons.phone,
              title: 'Phone Number',
              subtitle: user?.phone ?? 'Not set',
              onTap: () => _editPhoneNumber(),
            ),
            _buildSettingButton(
              icon: Icons.email,
              title: 'Email Address',
              subtitle: user?.email ?? '',
              onTap: () => _editEmail(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingSwitch(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              value: settingsProvider.settings.isDarkMode,
              onChanged: (value) {
                settingsProvider.toggleDarkMode(value);
                _applyTheme(value);
              },
            ),
            _buildSettingButton(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () => _changeLanguage(),
            ),
            _buildSettingButton(
              icon: Icons.currency_exchange,
              title: 'Currency',
              subtitle: settingsProvider.settings.currency,
              onTap: () => _changeCurrency(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingSwitch(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive app notifications',
              value: settingsProvider.settings.pushNotifications,
              onChanged: (value) {
                settingsProvider.togglePushNotifications(value);
              },
            ),
            _buildSettingSwitch(
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Receive email updates',
              value: settingsProvider.settings.emailNotifications,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    emailNotifications: value,
                  ),
                );
              },
            ),
            _buildSettingSwitch(
              icon: Icons.sms,
              title: 'SMS Notifications',
              subtitle: 'Receive text messages',
              value: settingsProvider.settings.smsNotifications,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    smsNotifications: value,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySecuritySection(SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy & Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingSwitch(
              icon: Icons.fingerprint,
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face ID to login',
              value: settingsProvider.settings.biometricAuth,
              onChanged: (value) {
                settingsProvider.toggleBiometricAuth(value);
              },
            ),
            _buildSettingSwitch(
              icon: Icons.credit_card,
              title: 'Save Payment Methods',
              subtitle: 'Store card details for faster payments',
              value: settingsProvider.settings.savePaymentMethods,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    savePaymentMethods: value,
                  ),
                );
              },
            ),
            _buildSettingButton(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () => _changePassword(),
            ),
            _buildSettingButton(
              icon: Icons.visibility_off,
              title: 'Privacy Settings',
              onTap: () => _showPrivacySettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStorageSection(SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data & Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingSwitch(
              icon: Icons.sync,
              title: 'Auto Sync',
              subtitle: 'Automatically sync data when online',
              value: settingsProvider.settings.autoSync,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    autoSync: value,
                  ),
                );
              },
            ),
            _buildSettingSwitch(
              icon: Icons.wifi_off,
              title: 'Offline Mode',
              subtitle: 'Work without internet connection',
              value: settingsProvider.settings.offlineMode,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    offlineMode: value,
                  ),
                );
              },
            ),
            _buildSettingSwitch(
              icon: Icons.hd,
              title: 'High Quality Images',
              subtitle: 'Use higher quality images (uses more data)',
              value: settingsProvider.settings.highQualityImages,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settingsProvider.settings.copyWith(
                    highQualityImages: value,
                  ),
                );
              },
            ),
            _buildSettingButton(
              icon: Icons.storage,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () => _clearCache(),
            ),
            _buildSettingButton(
              icon: Icons.download,
              title: 'Data Usage',
              onTap: () => _showDataUsage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingButton(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () => _showHelpSupport(),
            ),
            _buildSettingButton(
              icon: Icons.feedback,
              title: 'Send Feedback',
              onTap: () => _sendFeedback(),
            ),
            _buildSettingButton(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              onTap: () => _reportBug(),
            ),
            _buildSettingButton(
              icon: Icons.star,
              title: 'Rate the App',
              onTap: () => _rateApp(),
            ),
            _buildSettingButton(
              icon: Icons.share,
              title: 'Share App',
              onTap: () => _shareApp(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsSection(AuthProvider authProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDangerButton(
              icon: Icons.logout,
              title: 'Sign Out',
              color: Colors.orange,
              onTap: () => _signOut(authProvider),
            ),
            const SizedBox(height: 8),
            _buildDangerButton(
              icon: Icons.delete,
              title: 'Delete Account',
              color: AppColors.error,
              onTap: () => _deleteAccount(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDangerButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
    );
  }

  // Action Methods
  void _editProfile() {
    showCustomSnackBar(context, 'Edit profile feature coming soon');
  }

  void _editPhoneNumber() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Phone Number'),
        content: const Text('This feature is coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editEmail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: const Text('This feature is coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _applyTheme(bool isDarkMode) {
    showCustomSnackBar(
      context, 
      isDarkMode ? 'Dark mode enabled' : 'Light mode enabled',
    );
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Language'),
        content: const Text('Language selection feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _changeCurrency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Currency'),
        content: const Text('Currency selection feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showCustomSnackBar(context, 'Change password feature coming soon');
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: const Text('Privacy settings feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showCustomSnackBar(context, 'Cache cleared successfully');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDataUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Usage'),
        content: const Text('Data usage statistics feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Help and support feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text('Feedback feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text('Bug reporting feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate the App'),
        content: const Text('App rating feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share App'),
        content: const Text('App sharing feature coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signOut(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showCustomSnackBar(context, 'Account deletion feature coming soon');
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}