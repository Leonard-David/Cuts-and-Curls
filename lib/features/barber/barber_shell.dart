import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
import 'package:sheersync/features/barber/chat/barber_chat_list_screen.dart';
import 'package:sheersync/features/shared/widgets/bottom_nav.dart';
import '../../features/auth/controllers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'earnings/barber_earning_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_currentIndex].label),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // User profile menu
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onSelected: (value) {
              _handleMenuSelection(value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined),
                    SizedBox(width: 8),
                    Text('Logout'),
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
      floatingActionButton: _currentIndex == 1 // Appointments tab
          ? FloatingActionButton(
              onPressed: () {
                // Add new appointment functionality
                _addNewAppointment();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        // Navigate to profile screen
        break;
      case 'settings':
        // Navigate to settings screen
        break;
      case 'logout':
        _showLogoutConfirmation();
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                _logout();
              },
              child: const Text('Logout'),
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
    // Navigate to add appointment screen
    // We'll implement this later
  }
}