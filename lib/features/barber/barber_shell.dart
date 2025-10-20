// lib/features/barber/barber_shell.dart
import 'package:flutter/material.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
import 'package:sheersync/features/barber/dashboard/dashboard_screen.dart';
import 'package:sheersync/features/barber/services/barber_services_screen.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';

class BarberShell extends StatefulWidget {
  const BarberShell({super.key});

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    BarberDashboardScreen(),
    NotificationCenterScreen(), // Promotions & notifications
    BarberServicesScreen(),     // Add new service
    BarberAppointmentsScreen(), // Schedule / Bookings
    ChatScreen(peerId: '', peerName: '',),               // Chat with clients
  ];


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Promotion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle, color: AppColors.primary),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
