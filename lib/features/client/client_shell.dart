import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/features/barber/profile/barber_profile_screen.dart';
import 'package:sheersync/features/client/bookings/client_appointment_details_screen.dart';
import 'package:sheersync/features/client/bookings/confirm_booking_screen.dart';
import 'package:sheersync/features/client/bookings/my_bookings_screen.dart';
import 'package:sheersync/features/client/bookings/select_barber_screen.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';
import 'package:sheersync/features/client/chat/client_chat_list_screen.dart';
import 'package:sheersync/features/client/home/home_screen.dart';
import 'package:sheersync/features/client/payments/payment_history_screen.dart';
import 'package:sheersync/features/client/payments/payments_screen.dart';
import 'package:sheersync/features/client/profile/client_profile_screen.dart';
import 'package:sheersync/features/client/reviews/review_screen.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/providers/notification_provider.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation stack for each tab to handle nested navigation
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Bookings
    GlobalKey<NavigatorState>(), // Messages
    GlobalKey<NavigatorState>(), // Payments
  ];

  // Current screen titles based on navigation state
  String _currentTitle = 'Home';
  final List<String> _baseTitles = [
    'Home',
    'My Bookings',
    'Messages',
    'Payments'
  ];

  // Track navigation history for back button
  final Map<int, List<String>> _navigationHistory = {
    0: ['/'],
    1: ['/'],
    2: ['/'],
    3: ['/'],
  };

  @override
  void initState() {
    super.initState();
    // Initialize notification provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      if (authProvider.user != null) {
        notificationProvider.loadNotifications(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(notificationProvider),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _buildFloatingActionButton(),
        drawer: _buildDrawer(authProvider),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(NotificationProvider notificationProvider) {
    return AppBar(
      title: Text(
        _currentTitle,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 1,
      centerTitle: false,
      titleSpacing: 16,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
      actions: [
        // Notification icon with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: _navigateToNotifications,
              tooltip: 'Notifications',
            ),
            if (notificationProvider.hasUnread)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationProvider.unreadNotifications.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        // Home Tab - Enhanced with real-time data
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _buildHomeScreenContent(settings),
              settings: settings,
            );
          },
          reportsRouteUpdateToEngine: true,
        ),
        // Bookings Tab - Enhanced with real-time updates
        Navigator(
          key: _navigatorKeys[1],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _buildBookingsScreenContent(settings),
              settings: settings,
            );
          },
          reportsRouteUpdateToEngine: true,
        ),
        // Messages Tab - Enhanced with offline support
        Navigator(
          key: _navigatorKeys[2],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _buildMessagesScreenContent(settings),
              settings: settings,
            );
          },
          reportsRouteUpdateToEngine: true,
        ),
        // Payments Tab - Enhanced with Stripe integration
        Navigator(
          key: _navigatorKeys[3],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _buildPaymentsScreenContent(settings),
              settings: settings,
            );
          },
          reportsRouteUpdateToEngine: true,
        ),
      ],
    );
  }

  Widget _buildHomeScreenContent(RouteSettings settings) {
    switch (settings.name) {
      case '/barber/profile':
        final barber = settings.arguments as UserModel;
        return BarberProfileScreen(barber: barber);
      case '/barber/services':
        final barber = settings.arguments as UserModel;
        return SelectServiceScreen(barber: barber);
      case '/booking/select-barber':
        return const SelectBarberScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildBookingsScreenContent(RouteSettings settings) {
    switch (settings.name) {
      case '/booking/select-barber':
        return const SelectBarberScreen();
      case '/booking/select-service':
        final barber = settings.arguments as UserModel;
        return SelectServiceScreen(barber: barber);
      case '/booking/confirm':
        final arguments = settings.arguments as Map<String, dynamic>;
        return ConfirmBookingScreen(
          barber: arguments['barber'],
          service: arguments['service'],
          selectedDateTime: arguments['selectedDateTime'],
        );
      case '/booking/details':
        final appointment = settings.arguments as AppointmentModel;
        return ClientAppointmentDetailsScreen(appointment: appointment);
      case '/booking/review':
        final arguments = settings.arguments as Map<String, dynamic>;
        return ReviewScreen(
          barberId: arguments['barberId'],
          appointmentId: arguments['appointmentId'],
          barberName: arguments['barberName'],
        );
      default:
        return const MyBookingsScreen();
    }
  }

  Widget _buildMessagesScreenContent(RouteSettings settings) {
    switch (settings.name) {
      case '/chat':
        final chatRoom = settings.arguments as ChatRoom;
        return ChatScreen(chatRoom: chatRoom);
      default:
        return const ClientChatListScreen();
    }
  }

  Widget _buildPaymentsScreenContent(RouteSettings settings) {
    switch (settings.name) {
      case '/payment/history':
        return const PaymentHistoryScreen();
      default:
        return const PaymentsScreen();
    }
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
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment_outlined),
          activeIcon: Icon(Icons.payment),
          label: 'Payments',
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Home - Quick booking
        return FloatingActionButton(
          onPressed: _navigateToSelectBarber,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 4,
          tooltip: 'Quick Booking',
          child: const Icon(Icons.cut_rounded, size: 28),
        );
      case 1: // Bookings - Create new booking
        return FloatingActionButton(
          onPressed: _navigateToSelectBarber,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
          tooltip: 'New Booking',
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
          // Drawer Header with User Info
          _buildDrawerHeader(authProvider),
          // Quick Actions Section
          _buildQuickActionsSection(),
          const Divider(),
          // Settings Section
          _buildSettingsSection(),
          const Divider(),
          // Support Section
          _buildSupportSection(),
          const Divider(),
          // Logout Section
          _buildLogoutSection(authProvider),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: authProvider.user?.profileImage != null
                ? NetworkImage(authProvider.user!.profileImage!)
                : null,
            child: authProvider.user?.profileImage == null
                ? Icon(Icons.person, size: 30, color: AppColors.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            authProvider.user?.fullName ?? 'Client',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Client Account',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.user?.email ?? '',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.home,
          title: 'Home',
          onTap: () => _closeDrawerAndNavigate(() => _setCurrentIndex(0)),
        ),
        _buildDrawerItem(
          icon: Icons.person,
          title: 'My Profile',
          onTap: () => _closeDrawerAndNavigate(() => _navigateToProfile()),
        ),
        _buildDrawerItem(
          icon: Icons.calendar_today,
          title: 'My Bookings',
          onTap: () => _closeDrawerAndNavigate(() => _setCurrentIndex(1)),
        ),
        _buildDrawerItem(
          icon: Icons.chat,
          title: 'Messages',
          onTap: () => _closeDrawerAndNavigate(() => _setCurrentIndex(2)),
        ),
        _buildDrawerItem(
          icon: Icons.payment,
          title: 'Payments',
          onTap: () => _closeDrawerAndNavigate(() => _setCurrentIndex(3)),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () => _closeDrawerAndNavigate(_navigateToSettings),
        ),
        _buildDrawerItem(
          icon: Icons.notifications,
          title: 'Notification Settings',
          onTap: () => _closeDrawerAndNavigate(_navigateToNotificationSettings),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () => _closeDrawerAndNavigate(_showHelpSupport),
        ),
        _buildDrawerItem(
          icon: Icons.share,
          title: 'Share App',
          onTap: () => _closeDrawerAndNavigate(_shareApp),
        ),
        _buildDrawerItem(
          icon: Icons.info_outline,
          title: 'About',
          onTap: () => _closeDrawerAndNavigate(_showAbout),
        ),
      ],
    );
  }

  Widget _buildLogoutSection(AuthProvider authProvider) {
    return _buildDrawerItem(
      icon: Icons.logout,
      title: 'Logout',
      color: AppColors.error,
      onTap: () =>
          _closeDrawerAndNavigate(() => _showLogoutConfirmation(authProvider)),
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

  // Navigation Methods
  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Pop to first route if same tab is tapped
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      _updateNavigationHistory(index, '/');
    } else {
      _setCurrentIndex(index);
    }
  }

  void _setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
      _currentTitle = _baseTitles[index];
    });
  }

  void _updateNavigationHistory(int tabIndex, String route) {
    if (!_navigationHistory[tabIndex]!.contains(route)) {
      _navigationHistory[tabIndex]!.add(route);
    }
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentIndex];
    final currentHistory = _navigationHistory[_currentIndex]!;

    // Check if we can pop the current navigator
    if (currentNavigator.currentState?.canPop() == true) {
      currentNavigator.currentState?.pop();

      // Update history
      if (currentHistory.length > 1) {
        currentHistory.removeLast();
        _updateTitleFromHistory();
      }
      return false;
    }

    // If we're on the first route of the current tab, allow back to exit app
    return true;
  }

  void _updateTitleFromHistory() {
    final currentHistory = _navigationHistory[_currentIndex]!;
    final currentRoute = currentHistory.last;

    setState(() {
      switch (currentRoute) {
        case '/barber/profile':
          _currentTitle = 'Professional Profile';
          break;
        case '/booking/select-barber':
          _currentTitle = 'Choose Professional';
          break;
        case '/booking/select-service':
          _currentTitle = 'Select Service';
          break;
        case '/booking/confirm':
          _currentTitle = 'Confirm Booking';
          break;
        case '/booking/details':
          _currentTitle = 'Appointment Details';
          break;
        case '/chat':
          _currentTitle = 'Chat';
          break;
        case '/payment/history':
          _currentTitle = 'Payment History';
          break;
        default:
          _currentTitle = _baseTitles[_currentIndex];
      }
    });
  }

  // Helper method to close drawer and then execute navigation
  void _closeDrawerAndNavigate(VoidCallback navigationCallback) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), navigationCallback);
  }

  // Navigation methods
  void _navigateToProfile() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      _pushScreen(
          0, ClientProfileScreen(user: authProvider.user!), 'My Profile');
    }
  }

  void _navigateToSelectBarber() {
    _pushScreen(
        _currentIndex, const SelectBarberScreen(), 'Choose Professional');
  }

  void _navigateToSettings() {
    _pushScreen(_currentIndex, const SettingsScreen(), 'Settings');
  }

  void _navigateToNotificationSettings() {
    _pushScreen(
        _currentIndex, const NotificationCenterScreen(), 'Notifications');
  }

  void _navigateToNotifications() {
    _pushScreen(
        _currentIndex, const NotificationCenterScreen(), 'Notifications');
  }

  void _pushScreen(int tabIndex, Widget screen, String title) {
    final navigator = _navigatorKeys[tabIndex];

    setState(() {
      _currentTitle = title;
    });

    _updateNavigationHistory(tabIndex, '/${screen.runtimeType}');

    navigator.currentState?.push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
            'Contact our support team at support@sheersync.com or call +1-555-HELP for assistance.'),
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
    // Implement share functionality
    showCustomSnackBar(
      context,
      'Share functionality will be implemented here',
      type: SnackBarType.info,
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SheerSync'),
        content: const Text(
          'SheerSync v1.0.0\n\n'
          'Connect with professional barbers and hairstylists for your grooming needs. '
          'Book appointments, chat with professionals, and make secure payments all in one app.',
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

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}
