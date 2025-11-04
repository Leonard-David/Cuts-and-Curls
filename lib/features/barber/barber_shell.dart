import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context); // FIX: Store provider in variable

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
              _handleMenuSelection(value, authProvider); // FIX: Pass authProvider
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

  void _handleMenuSelection(String value, AuthProvider authProvider) { // FIX: Add authProvider parameter
    switch (value) {
      case 'profile':
        _navigateToProfile(authProvider); // FIX: Pass authProvider
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
        _showLogoutConfirmation(authProvider); // FIX: Pass authProvider
        break;
    }
  }

  void _navigateToProfile(AuthProvider authProvider) { // FIX: Add authProvider parameter
    if (authProvider.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarberProfileScreen(barber: authProvider.user!), // FIX: Pass current user as barber
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
        builder: (context) => const BarberServicesScreen(), // Navigate to service management
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

  void _showLogoutConfirmation(AuthProvider authProvider) { // FIX: Add authProvider parameter
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
                _logout(authProvider); // FIX: Pass authProvider
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

  void _logout(AuthProvider authProvider) { // FIX: Add authProvider parameter
    authProvider.signOut();
  }

  void _addNewAppointment() {
    // TODO: Navigate to add appointment screen
    _showComingSoon('Add New Appointment');
  }
}