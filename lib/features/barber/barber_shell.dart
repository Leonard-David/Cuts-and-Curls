import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
import 'package:sheersync/features/barber/appointments/create_appointment_screen.dart';
import 'package:sheersync/features/barber/chat/barber_chat_list_screen.dart';
import 'package:sheersync/features/barber/profile/barber_profile_screen.dart';
import 'package:sheersync/features/barber/services/barber_services_screen.dart';
import 'package:sheersync/features/barber/services/manage_availability_screen.dart';
import 'package:sheersync/features/shared/widgets/bottom_nav.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';
import '../../features/auth/controllers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'earnings/barber_earning_screen.dart';
import 'package:sheersync/core/constants/colors.dart'; 

class BarberShell extends StatefulWidget {
  const BarberShell({super.key});

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  int _currentIndex = 0;

  // Screens for bottom navigation
  final List<Widget> _screens = [
    const DashboardScreen(),
    const BarberChatListScreen(), 
    const BarberAppointmentsScreen(),
    const BarberEarningScreen(),
  ];

  // Bottom navigation items
  final List<BottomNavigationItem> _navItems = [
    BottomNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    BottomNavigationItem(
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      label: 'Messages',
    ),
    BottomNavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Appointments',
    ),
    BottomNavigationItem(
      icon: Icons.attach_money_outlined,
      activeIcon: Icons.attach_money,
      label: 'Earnings',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Method to show appointment options bottom sheet
  void _showAppointmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Options
              _buildActionOption(
                icon: Icons.add_circle_outline_rounded,
                title: 'Create Appointment',
                subtitle: 'Schedule a new appointment',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAppointmentScreen(),
                    ),
                  );
                },
              ),
              _buildActionOption(
                icon: Icons.construction_rounded,
                title: 'Add Service',
                subtitle: 'Create a new service',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarberServicesScreen(),
                    ),
                  );
                },
              ),
              _buildActionOption(
                icon: Icons.access_time_rounded,
                title: 'Manage Availability',
                subtitle: 'Set working hours',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageAvailabilityScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Cancel Button
              SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: AppColors.background,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navItems[_currentIndex].label,
          style: TextStyle(color: AppColors.text),  
        ),
        backgroundColor: AppColors.background,  
        foregroundColor: AppColors.text, 
        elevation: 1,
        actions: [
          // User profile menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary, 
              child: Icon(Icons.person, color: AppColors.onPrimary), 
            ),
            onSelected: (value) {
              _handleMenuSelection(value, authProvider);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.text), 
                    const SizedBox(width: 8),
                    Text(
                      'My Profile',
                      style: TextStyle(color: AppColors.text),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'availability',
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.text), 
                    const SizedBox(width: 8),
                    Text(
                      'Availability',
                      style: TextStyle(color: AppColors.text), 
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'services',
                child: Row(
                  children: [
                    Icon(Icons.cut, color: AppColors.text),  
                    const SizedBox(width: 8),
                    Text(
                      'My Services',
                      style: TextStyle(color: AppColors.text),  
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: AppColors.text),  
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(color: AppColors.text),  
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, color: AppColors.error),  
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),  
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _currentIndex == 2 // Appointments tab
          ? FloatingActionButton(
              onPressed: _showAppointmentOptions,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }

  void _handleMenuSelection(String value, AuthProvider authProvider) {
    switch (value) {
      case 'profile':
        _navigateToProfile(authProvider);
        break;
      case 'availability':
        _navigateToAvailability();
        break;
      case 'services':
        _navigateToServices();
        break;
      case 'settings':
        _navigateToSettings();
        break;
      case 'logout':
        _showLogoutConfirmation(authProvider);
        break;
    }
  }

  void _navigateToProfile(AuthProvider authProvider) {
    if (authProvider.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarberProfileScreen(barber: authProvider.user!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User data not available'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageAvailabilityScreen(),
      ),
    );
  }

  void _navigateToServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarberServicesScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showLogoutConfirmation(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(color: AppColors.text),  
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary),  
          ),
          backgroundColor: AppColors.background,  
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),  
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout(authProvider);
              },
              child: Text(
                'Logout',
                style: TextStyle(color: AppColors.error),  
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout(AuthProvider authProvider) {
    authProvider.signOut();
  }
}