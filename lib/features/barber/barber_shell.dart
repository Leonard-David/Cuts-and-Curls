import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:sheersync/features/barber/appointments/appointment_details_screen.dart';
import 'package:sheersync/features/barber/appointments/barber_appointments_screen.dart';
import 'package:sheersync/features/barber/appointments/create_appointment_screen.dart';
import 'package:sheersync/features/barber/chat/barber_chat_list_screen.dart';
import 'package:sheersync/features/barber/dashboard/dashboard_screen.dart';
import 'package:sheersync/features/barber/earnings/barber_earning_screen.dart';
import 'package:sheersync/features/barber/marketing/marketing_screen.dart';
import 'package:sheersync/features/barber/onboarding/stripe_connect_screen.dart';
import 'package:sheersync/features/barber/profile/barber_profile_screen.dart';
import 'package:sheersync/features/barber/services/barber_services_screen.dart';
import 'package:sheersync/features/barber/services/manage_availability_screen.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';
import 'package:sheersync/data/models/appointment_model.dart';
import 'package:sheersync/data/models/chat_room_model.dart';

class BarberShell extends StatefulWidget {
  const BarberShell({super.key});

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation stack for each tab to handle nested navigation
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Dashboard
    GlobalKey<NavigatorState>(), // Messages
    GlobalKey<NavigatorState>(), // Appointments
    GlobalKey<NavigatorState>(), // Earnings
  ];

  // Current screen titles based on navigation state
  String _currentTitle = 'Dashboard';
  final List<String> _baseTitles = [
    'Dashboard',
    'Messages',
    'Appointments',
    'Earnings'
  ];

  // Track if we're showing a detail screen (to show back button)
  bool _showBackButton = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _buildFloatingActionButton(),
        drawer: _buildDrawer(authProvider),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          if (_showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackPress,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 1,
      centerTitle: false,
      titleSpacing: 16,
      actions: _buildAppBarActions(),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    // Different actions based on current screen
    switch (_currentIndex) {
      case 0: // Dashboard
        return [
          _buildNotificationAction(),
        ];
      case 1: // Messages
        return [
          _buildNotificationAction(),
        ];
      case 2: // Appointments
        return [
          _buildAppBarAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Appointments',
            onPressed: _refreshAppointments,
          ),
          _buildNotificationAction(),
        ];
      case 3: // Earnings
        return [
          _buildNotificationAction(),
        ];
      default:
        return [
          _buildNotificationAction(),
        ];
    }
  }

  Widget _buildNotificationAction() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _navigateToNotifications,
          tooltip: 'Notifications',
        ),
        // Unread notification indicator would go here
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        // Dashboard Tab
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              )
            ];
          },
        ),
        // Messages Tab
        Navigator(
          key: _navigatorKeys[1],
          onGenerateRoute: (settings) {
            Widget screen;

            switch (settings.name) {
              case '/chat':
                final chatRoom = settings.arguments as ChatRoom;
                screen = ChatScreen(chatRoom: chatRoom);
                break;
              default:
                screen = const BarberChatListScreen();
            }

            return MaterialPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const BarberChatListScreen(),
              )
            ];
          },
        ),
        // Appointments Tab
        Navigator(
          key: _navigatorKeys[2],
          onGenerateRoute: (settings) {
            Widget screen;

            switch (settings.name) {
              case '/appointment/create':
                screen = const CreateAppointmentScreen();
                break;
              case '/appointment/details':
                final appointment = settings.arguments as AppointmentModel;
                screen = AppointmentDetailsScreen(appointment: appointment);
                break;
              default:
                screen = const BarberAppointmentsScreen();
            }

            return MaterialPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const BarberAppointmentsScreen(),
              )
            ];
          },
        ),
        // Earnings Tab
        Navigator(
          key: _navigatorKeys[3],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const BarberEarningScreen(),
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const BarberEarningScreen(),
              )
            ];
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_outlined),
          activeIcon: Icon(Icons.attach_money),
          label: 'Earnings',
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show FAB only on specific tabs
    switch (_currentIndex) {
      case 1: // Messages - No FAB needed
        return null;
      case 2: // Appointments - Create appointment
        return FloatingActionButton(
          onPressed: _showAppointmentOptions,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
          child: const Icon(Icons.add_rounded, size: 28),
        );
      default:
        return null;
    }
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 30, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.user?.fullName ?? 'Professional',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.user?.userType == 'barber'
                      ? 'Professional Barber'
                      : 'Hairstylist',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Quick Actions
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              _closeDrawerAndNavigate(() {
                _setCurrentIndex(0);
              });
            },
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'My Profile',
            onTap: () =>
                _closeDrawerAndNavigate(() => _navigateToProfile(authProvider)),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Appointments',
            onTap: () {
              _closeDrawerAndNavigate(() {
                _setCurrentIndex(2);
              });
            },
          ),
          _buildDrawerItem(
            icon: Icons.construction,
            title: 'My Services',
            onTap: () => _closeDrawerAndNavigate(_navigateToServices),
          ),
          _buildDrawerItem(
            icon: Icons.access_time,
            title: 'Availability',
            onTap: () => _closeDrawerAndNavigate(_navigateToAvailability),
          ),
          _buildDrawerItem(
            icon: Icons.attach_money,
            title: 'Earnings',
            onTap: () {
              _closeDrawerAndNavigate(() {
                _setCurrentIndex(3);
              });
            },
          ),
          _buildDrawerItem(
            icon: Icons.chat,
            title: 'Messages',
            onTap: () {
              _closeDrawerAndNavigate(() {
                _setCurrentIndex(1);
              });
            },
          ),
          // ADD MARKETING ITEM TO DRAWER
          _buildDrawerItem(
            icon: Icons.campaign,
            title: 'Marketing Tools',
            onTap: () => _closeDrawerAndNavigate(_navigateToMarketing),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.payment,
            title: 'Payment Setup',
            onTap: () => _closeDrawerAndNavigate(_navigateToPaymentSetup),
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () => _closeDrawerAndNavigate(_navigateToSettings),
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _closeDrawerAndNavigate(_showHelpSupport),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            color: AppColors.error,
            onTap: () => _closeDrawerAndNavigate(
                () => _showLogoutConfirmation(authProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.text),
      title: Text(title, style: TextStyle(color: color ?? AppColors.text)),
      onTap: onTap,
    );
  }

  // Helper method to close drawer and then execute navigation
  void _closeDrawerAndNavigate(VoidCallback navigationCallback) {
    // Close the drawer first
    Navigator.of(context).pop();

    // Then execute the navigation callback after a small delay
    // to ensure the drawer is fully closed
    Future.delayed(const Duration(milliseconds: 100), navigationCallback);
  }

  // Navigation Methods
  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Pop to first route if same tab is tapped
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
    _setCurrentIndex(index);
  }

  void _setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
      _currentTitle = _baseTitles[index];
      _showBackButton = false;
    });
  }

  void _navigateToMarketing() {
    _pushScreen(const MarketingScreen(), 'Marketing Tools');
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentIndex];

    // Check if we can pop the current navigator
    if (currentNavigator.currentState?.canPop() == true) {
      currentNavigator.currentState?.pop();
      _updateTitleAfterPop();
      return false;
    }

    // If we're on the first route of the current tab, allow back to exit app
    return true;
  }

  void _handleBackPress() {
    final currentNavigator = _navigatorKeys[_currentIndex];
    if (currentNavigator.currentState?.canPop() == true) {
      currentNavigator.currentState?.pop();
      _updateTitleAfterPop();
    }
  }

  void _updateTitleAfterPop() {
    // This would need to be more sophisticated in a real app
    // For now, we'll reset to base title after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final currentNavigator = _navigatorKeys[_currentIndex];
        final canPop = currentNavigator.currentState?.canPop() == true;
        setState(() {
          _showBackButton = canPop;
          if (!canPop) {
            _currentTitle = _baseTitles[_currentIndex];
          }
        });
      }
    });
  }

  // Navigation methods
  void _navigateToProfile(AuthProvider authProvider) {
    if (authProvider.user != null) {
      _pushScreen(
        BarberProfileScreen(barber: authProvider.user!),
        'My Profile',
      );
    }
  }

  void _navigateToServices() {
    _pushScreen(const BarberServicesScreen(), 'My Services');
  }

  void _navigateToAvailability() {
    _pushScreen(const ManageAvailabilityScreen(), 'Availability');
  }

  void _navigateToPaymentSetup() {
    _pushScreen(const StripeConnectScreen(), 'Payment Setup');
  }

  void _navigateToSettings() {
    _pushScreen(const SettingsScreen(), 'Settings');
  }

  void _navigateToNotifications() {
    _pushScreen(const NotificationCenterScreen(), 'Notifications');
  }

  void _pushScreen(Widget screen, String title) {
    final currentNavigator = _navigatorKeys[_currentIndex];

    setState(() {
      _currentTitle = title;
      _showBackButton = true;
    });

    currentNavigator.currentState?.push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

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
              _buildActionOption(
                icon: Icons.add_circle_outline_rounded,
                title: 'Create Appointment',
                subtitle: 'Schedule a new appointment',
                onTap: () {
                  Navigator.pop(context);
                  _pushScreen(
                      const CreateAppointmentScreen(), 'Create Appointment');
                },
              ),
              _buildActionOption(
                icon: Icons.construction_rounded,
                title: 'Add Service',
                subtitle: 'Create a new service',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToServices();
                },
              ),
              _buildActionOption(
                icon: Icons.access_time_rounded,
                title: 'Manage Availability',
                subtitle: 'Set working hours',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAvailability();
                },
              ),
              const SizedBox(height: 8),
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
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _refreshAppointments() {
    // This would typically refresh the appointments data
    showCustomSnackBar(
      context,
      'Refreshing appointments...',
      type: SnackBarType.success,
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content:
            const Text('Help and support resources will be available here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(AuthProvider authProvider) {
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
                authProvider.signOut();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
