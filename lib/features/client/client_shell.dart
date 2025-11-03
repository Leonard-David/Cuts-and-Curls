import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/features/client/chat/client_chat_list_screen.dart';
import 'package:sheersync/features/client/profile/client_profile_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';
import 'package:sheersync/features/shared/widgets/bottom_nav.dart';
import '../../features/auth/controllers/auth_provider.dart';
import 'home/home_screen.dart';
import 'bookings/my_bookings_screen.dart';
import 'bookings/select_barber_screen.dart'; // ADD IMPORT for quick booking
import 'package:sheersync/core/constants/colors.dart'; // ADD IMPORT

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;

  // Screens for bottom navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const ClientChatListScreen(),
    const MyBookingsScreen(),
    const ClientProfileScreen(), // This will now be the main profile screen
  ];

  // Bottom navigation items
  final List<BottomNavigationItem> _navItems = [
    BottomNavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    BottomNavigationItem(
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      label: 'Messages',
    ),
    BottomNavigationItem(
      icon: Icons.book_online_outlined,
      activeIcon: Icons.book_online,
      label: 'Bookings',
    ),
    BottomNavigationItem(
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navItems[_currentIndex].label,
          style: TextStyle(color: AppColors.text), // UPDATE: Use text color
        ),
        backgroundColor: AppColors.background, // UPDATE: Use background color
        foregroundColor: AppColors.text, // UPDATE: Use text color
        elevation: 1,
        actions: _buildAppBarActions(authProvider, notificationProvider),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _currentIndex == 0 // Home tab
          ? FloatingActionButton(
              onPressed: _quickBook,
              backgroundColor: AppColors.accent, // UPDATE: Use accent color
              child: Icon(Icons.cut, color: AppColors.onPrimary), // UPDATE: Use onPrimary color
            )
          : null,
    );
  }

  List<Widget> _buildAppBarActions(AuthProvider authProvider, NotificationProvider notificationProvider) {
    if (_currentIndex == 3) { // Profile tab - show settings icon
      return [
        IconButton(
          icon: Icon(Icons.settings, color: AppColors.text), // UPDATE: Use text color
          onPressed: _openSettings,
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
      ];
    } else {
      return [
        // Notification icon for other tabs
        IconButton(
          icon: StreamBuilder<int>(
            stream: notificationProvider.getUnreadCount(authProvider.user?.id ?? ''),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: AppColors.accent, // UPDATE: Use accent color
                child: Icon(Icons.notifications_outlined, color: AppColors.text), // UPDATE: Use text color
              );
            },
          ),
          onPressed: _openNotifications,
        ),
        const SizedBox(width: 8),
      ];
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationCenterScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _quickBook() {
    // Navigate to booking flow
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => const SelectBarberScreen(),
      ),
    );
  }
}