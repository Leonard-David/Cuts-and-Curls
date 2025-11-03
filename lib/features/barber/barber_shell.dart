import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
import 'package:sheersync/features/barber/chat/barber_chat_list_screen.dart';
import 'package:sheersync/features/barber/services/manage_availability_screen.dart';
import 'package:sheersync/features/barber/services/add_edit_service_screen.dart';
import 'package:sheersync/features/shared/widgets/bottom_nav.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';
import '../../features/auth/controllers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'earnings/barber_earning_screen.dart';
import 'package:sheersync/core/constants/colors.dart'; // ADD IMPORT

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
    const BarberChatListScreen(), // Updated
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

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navItems[_currentIndex].label,
          style: TextStyle(color: AppColors.text), // UPDATE: Use text color
        ),
        backgroundColor: AppColors.background, // UPDATE: Use background color
        foregroundColor: AppColors.text, // UPDATE: Use text color
        elevation: 1,
        actions: [
          // User profile menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary, // UPDATE: Use primary color
              child: Icon(Icons.person, color: AppColors.onPrimary), // UPDATE: Use onPrimary color
            ),
            onSelected: (value) {
              _handleMenuSelection(value);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.text), // UPDATE: Use text color
                    const SizedBox(width: 8),
                    Text(
                      'My Profile',
                      style: TextStyle(color: AppColors.text), // UPDATE: Use text color
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'availability',
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.text), // UPDATE: Use text color
                    const SizedBox(width: 8),
                    Text(
                      'Availability',
                      style: TextStyle(color: AppColors.text), // UPDATE: Use text color
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'services',
                child: Row(
                  children: [
                    Icon(Icons.cut, color: AppColors.text), // UPDATE: Use text color
                    const SizedBox(width: 8),
                    Text(
                      'My Services',
                      style: TextStyle(color: AppColors.text), // UPDATE: Use text color
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: AppColors.text), // UPDATE: Use text color
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(color: AppColors.text), // UPDATE: Use text color
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, color: AppColors.error), // UPDATE: Use error color
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error), // UPDATE: Use error color
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
              onPressed: () {
                // Add new appointment functionality
                _addNewAppointment();
              },
              backgroundColor: AppColors.accent, // UPDATE: Use accent color
              child: Icon(Icons.add, color: AppColors.onPrimary), // UPDATE: Use onPrimary color
            )
          : null,
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        _navigateToProfile();
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
        _showLogoutConfirmation();
        break;
    }
  }

  void _navigateToProfile() {
    // TODO: Navigate to barber profile screen
    _showComingSoon('Profile Management');
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
        builder: (context) => const AddEditServiceScreen(), // Navigate to service management
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.primary, // UPDATE: Use primary color
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(color: AppColors.text), // UPDATE: Use text color
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary), // UPDATE: Use secondary text color
          ),
          backgroundColor: AppColors.background, // UPDATE: Use background color
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary), // UPDATE: Use secondary text color
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: AppColors.error), // UPDATE: Use error color
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.signOut();
  }

  void _addNewAppointment() {
    // TODO: Navigate to add appointment screen
    _showComingSoon('Add New Appointment');
  }
}