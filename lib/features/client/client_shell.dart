import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/data/providers/chat_provider.dart';
import 'package:sheersync/data/providers/payment_provider.dart';
import 'package:sheersync/features/client/home/home_screen.dart';
import 'package:sheersync/features/client/bookings/my_bookings_screen.dart';
import 'package:sheersync/features/client/chat/client_chat_list_screen.dart';
import 'package:sheersync/features/client/payments/payments_screen.dart';
import 'package:sheersync/features/client/profile/client_profile_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation stack for each tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Bookings
    GlobalKey<NavigatorState>(), // Messages
    GlobalKey<NavigatorState>(), // Payments
  ];

  // Current screen title
  String _currentTitle = 'Home';

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        // Initialize all providers with real-time data
        context
            .read<AppointmentsProvider>()
            .loadClientAppointments(authProvider.user!.id);
        context
            .read<NotificationProvider>()
            .loadNotifications(authProvider.user!.id);
        context.read<ChatProvider>(); // Initialize chat provider
        context
            .read<PaymentProvider>()
            .loadClientPayments(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(notificationProvider),
            body: _buildBody(),
            bottomNavigationBar: _buildBottomNavigationBar(),
            floatingActionButton: _buildFloatingActionButton(authProvider),
            drawer: _buildDrawer(authProvider, notificationProvider),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(NotificationProvider notificationProvider) {
    return AppBar(
      title: Text(
        _currentTitle,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
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
                    notificationProvider.unreadNotifications.length > 99
                        ? '99+'
                        : notificationProvider.unreadNotifications.length
                            .toString(),
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        // Home Tab
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        ),
        // Bookings Tab
        Navigator(
          key: _navigatorKeys[1],
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => const MyBookingsScreen(),
          ),
        ),
        // Messages Tab
        Navigator(
          key: _navigatorKeys[2],
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => const ClientChatListScreen(),
          ),
        ),
        // Payments Tab
        Navigator(
          key: _navigatorKeys[3],
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => const PaymentsScreen(),
          ),
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

  Widget? _buildFloatingActionButton(AuthProvider authProvider) {
    if (authProvider.user == null) return null;

    switch (_currentIndex) {
      case 0: // Home - Quick booking
        return FloatingActionButton(
          onPressed: _navigateToBookingFlow,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 4,
          tooltip: 'Quick Booking',
          child: const Icon(Icons.add_rounded, size: 28),
        );
      case 1: // Bookings - Create new booking
        return FloatingActionButton(
          onPressed: _navigateToBookingFlow,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          tooltip: 'New Booking',
          child: const Icon(Icons.add_rounded, size: 28),
        );
      default:
        return null;
    }
  }

  Widget _buildDrawer(
      AuthProvider authProvider, NotificationProvider notificationProvider) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Header
          _buildDrawerHeader(authProvider),

          // Main Navigation Section
          _buildDrawerSection('Navigation', [
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => _closeDrawerAndNavigate(() => _setCurrentIndex(0)),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'My Profile',
              onTap: () => _closeDrawerAndNavigate(_navigateToProfile),
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
          ]),

          // Account Section
          _buildDrawerSection('Account', [
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => _closeDrawerAndNavigate(_navigateToSettings),
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notifications',
              badge: notificationProvider.hasUnread,
              onTap: () => _closeDrawerAndNavigate(_navigateToNotifications),
            ),
          ]),

          // Support Section
          _buildDrawerSection('Support', [
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => _closeDrawerAndNavigate(_showHelpSupport),
            ),
            _buildDrawerItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => _closeDrawerAndNavigate(_showAbout),
            ),
          ]),

          // Logout Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              color: AppColors.error,
              onTap: () => _closeDrawerAndNavigate(
                  () => _showLogoutConfirmation(authProvider)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider) {
    return UserAccountsDrawerHeader(
      accountName: Text(
        authProvider.user?.fullName ?? 'Client',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(
        authProvider.user?.email ?? 'client@example.com',
        style: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: authProvider.user?.profileImage != null
            ? NetworkImage(authProvider.user!.profileImage!)
            : null,
        child: authProvider.user?.profileImage == null
            ? const Icon(Icons.person, color: AppColors.primary)
            : null,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool badge = false,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: color ?? AppColors.text),
          if (badge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // Navigation Methods
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _updateTitle(index);
    });
  }

  void _setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
      _updateTitle(index);
    });
  }

  void _updateTitle(int index) {
    switch (index) {
      case 0:
        _currentTitle = 'Home';
        break;
      case 1:
        _currentTitle = 'My Bookings';
        break;
      case 2:
        _currentTitle = 'Messages';
        break;
      case 3:
        _currentTitle = 'Payments';
        break;
    }
  }

  void _closeDrawerAndNavigate(VoidCallback navigationCallback) {
    Navigator.of(context).pop(); // Close drawer
    Future.delayed(const Duration(milliseconds: 100), navigationCallback);
  }

  void _navigateToBookingFlow() {
    // This will be handled by the individual screens
    showCustomSnackBar(
      context,
      'Navigate to booking flow',
      type: SnackBarType.info,
    );
  }

  void _navigateToProfile() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientProfileScreen(user: authProvider.user!),
        ),
      );
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For assistance, contact our support team:\n\n'
          'Email: support@sheersync.com\n'
          'Phone: +1-555-HELP\n\n'
          'We\'re here to help you 24/7.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SheerSync'),
        content: const Text(
          'SheerSync v1.0.0\n\n'
          'Your all-in-one platform for connecting with professional barbers and hairstylists. '
          'Book appointments, communicate seamlessly, and manage payments with ease.',
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
}
