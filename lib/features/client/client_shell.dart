import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/adapters/hive_adapters.dart';
import 'package:sheersync/data/providers/auth_provider.dart';
import 'package:sheersync/data/providers/notification_provider.dart';
import 'package:sheersync/features/client/barber/barber_profile_screen.dart';
import 'package:sheersync/features/client/bookings/client_appointment_details_screen.dart';
import 'package:sheersync/features/client/bookings/my_bookings_screen.dart';
import 'package:sheersync/features/client/bookings/confirm_booking_screen.dart';
import 'package:sheersync/features/client/bookings/select_barber_screen.dart';
import 'package:sheersync/features/client/bookings/select_service_screen.dart';
import 'package:sheersync/features/client/chat/client_chat_list_screen.dart';
import 'package:sheersync/features/client/home/home_screen.dart';
import 'package:sheersync/features/client/payments/payment_history_screen.dart';
import 'package:sheersync/features/client/payments/payments_screen.dart';
import 'package:sheersync/features/client/profile/client_profile_screen.dart';
import 'package:sheersync/features/client/reviews/review_screen.dart';
import 'package:sheersync/features/client/reviews/special_offers_screen.dart';
import 'package:sheersync/features/shared/chat/chat_screen.dart';
import 'package:sheersync/features/shared/notification/notification_center_screen.dart';
import 'package:sheersync/features/shared/settings/settings_screen.dart';
import 'package:sheersync/data/models/chat_room_model.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/providers/appointments_provider.dart';

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

  // Track current route for each tab
  final List<String> _currentRoutes = ['/', '/', '/', '/'];

  // Current screen titles based on navigation state
  String _currentTitle = 'Home';
  final List<String> _baseTitles = [
    'Home',
    'My Bookings',
    'Messages',
    'Payments'
  ];

  // Track if showing a detail screen (to show back button)
  bool _showBackButton = false;
  bool _isRouteUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    // Initialize notification provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final appointmentsProvider = context.read<AppointmentsProvider>();

      if (authProvider.user != null) {
        notificationProvider.loadNotifications(authProvider.user!.id);
        appointmentsProvider.loadClientAppointments(authProvider.user!.id);
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
        bottomNavigationBar:
            _shouldShowBottomNav() ? _buildBottomNavigationBar() : null,
        floatingActionButton:
            _shouldShowBottomNav() ? _buildFloatingActionButton() : null,
        drawer: _shouldShowBottomNav()
            ? _buildDrawer(authProvider, notificationProvider)
            : null,
      ),
    );
  }

  bool _shouldShowBottomNav() {
    // Hide bottom nav when we're in chat list screen or any nested chat screens
    return _currentIndex != 2 || _currentRoutes[2] == '/';
  }

  PreferredSizeWidget _buildAppBar(NotificationProvider notificationProvider) {
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
      actions: _buildAppBarActions(notificationProvider),
      leading: _shouldShowBottomNav()
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackPress,
              tooltip: 'Back',
            ),
    );
  }

  List<Widget> _buildAppBarActions(NotificationProvider notificationProvider) {
    // Different actions based on current screen
    switch (_currentIndex) {
      case 0: // Home
        return [
          _buildAppBarAction(
            icon: Icons.local_offer_rounded,
            tooltip: 'Special Offers',
            onPressed: _navigateToSpecialOffers,
          ),
          _buildNotificationAction(notificationProvider),
        ];
      case 1: // Bookings
        return [
          _buildAppBarAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Bookings',
            onPressed: _refreshBookings,
          ),
          _buildNotificationAction(notificationProvider),
        ];
      case 2: // Messages - Only show notification action in chat list
        if (_currentRoutes[2] == '/') {
          return [
            _buildNotificationAction(notificationProvider),
          ];
        }
        return []; // No actions in chat screen
      case 3: // Payments
        return [
          _buildAppBarAction(
            icon: Icons.history_rounded,
            tooltip: 'Payment History',
            onPressed: _navigateToPaymentHistory,
          ),
          _buildNotificationAction(notificationProvider),
        ];
      default:
        return [
          _buildNotificationAction(notificationProvider),
        ];
    }
  }

  Widget _buildNotificationAction(NotificationProvider notificationProvider) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _navigateToNotifications,
          tooltip: 'Notifications',
        ),
        // Green dot indicator for unread notifications
        if (notificationProvider.hasUnread)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
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
        // Home Tab
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (settings) {
            Widget screen;

            switch (settings.name) {
              case '/barber/profile':
                final barber = settings.arguments as UserModel;
                screen = BarberProfileScreen(barber: barber);
                break;
              case '/barber/services':
                final barber = settings.arguments as UserModel;
                screen = SelectServiceScreen(barber: barber);
                break;
              case '/booking/select-barber':
                screen = const SelectBarberScreen();
                break;
              case '/offers/special':
                screen = const SpecialOffersScreen();
                break;
              default:
                screen = const HomeScreen();
            }

            return MaterialPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              )
            ];
          },
          observers: [_RouteObserver((route) => _updateRoute(0, route))],
        ),
        // Bookings Tab
        Navigator(
          key: _navigatorKeys[1],
          onGenerateRoute: (settings) {
            Widget screen;

            switch (settings.name) {
              case '/booking/select-barber':
                screen = const SelectBarberScreen();
                break;
              case '/booking/select-service':
                final barber = settings.arguments as UserModel;
                screen = SelectServiceScreen(barber: barber);
                break;
              case '/booking/confirm':
                final arguments = settings.arguments as Map<String, dynamic>;
                screen = ConfirmBookingScreen(
                  barber: arguments['barber'],
                  service: arguments['service'],
                  selectedDateTime: arguments['selectedDateTime'],
                );
                break;
              case '/booking/details':
                final appointment = settings.arguments as AppointmentModel;
                screen =
                    ClientAppointmentDetailsScreen(appointment: appointment);
                break;
              case '/booking/review':
                final arguments = settings.arguments as Map<String, dynamic>;
                screen = ReviewScreen(
                  barberId: arguments['barberId'],
                  appointmentId: arguments['appointmentId'],
                  barberName: arguments['barberName'],
                );
                break;
              default:
                screen = const MyBookingsScreen();
            }

            return MaterialPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const MyBookingsScreen(),
              )
            ];
          },
          observers: [_RouteObserver((route) => _updateRoute(1, route))],
        ),
        // Messages Tab
        Navigator(
          key: _navigatorKeys[2],
          onGenerateRoute: (settings) {
            Widget screen;

            switch (settings.name) {
              case '/chat':
                final chatRoom = settings.arguments as ChatRoom;
                screen = ChatScreen(chatRoom: chatRoom);
                break;
              default:
                screen = const ClientChatListScreen();
            }

            return MaterialPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const ClientChatListScreen(),
              )
            ];
          },
          observers: [_RouteObserver((route) => _updateRoute(2, route))],
        ),
        // Payments Tab
        Navigator(
          key: _navigatorKeys[3],
          onGenerateRoute: (settings) {
            Widget screen;

            switch (settings.name) {
              case '/payment/history':
                screen = const PaymentHistoryScreen();
                break;
              default:
                screen = const PaymentsScreen();
            }

            return MaterialPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              MaterialPageRoute(
                builder: (context) => const PaymentsScreen(),
              )
            ];
          },
          observers: [_RouteObserver((route) => _updateRoute(3, route))],
        ),
      ],
    );
  }

  void _updateRoute(int tabIndex, Route<dynamic>? route) {
    if (route != null && route is ModalRoute) {
      final routeName = route.settings.name ?? '/';
      
      // Prevent multiple scheduled updates
      if (!_isRouteUpdateScheduled) {
        _isRouteUpdateScheduled = true;
        
        // Use WidgetsBinding to schedule the state update after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isRouteUpdateScheduled = false;
          if (mounted) {
            setState(() {
              _currentRoutes[tabIndex] = routeName;
              // Update back button visibility
              _showBackButton =
                  _navigatorKeys[tabIndex].currentState?.canPop() == true;

              // Update title based on current route
              if (tabIndex == _currentIndex) {
                if (routeName == '/') {
                  _currentTitle = _baseTitles[tabIndex];
                } else if (routeName == '/chat') {
                  _currentTitle = 'Chat';
                } else if (routeName == '/barber/profile') {
                  _currentTitle = 'Barber Profile';
                } else if (routeName == '/barber/services') {
                  _currentTitle = 'Select Service';
                } else if (routeName == '/booking/select-barber') {
                  _currentTitle = 'Find Professional';
                } else if (routeName == '/booking/confirm') {
                  _currentTitle = 'Confirm Booking';
                } else if (routeName == '/booking/details') {
                  _currentTitle = 'Appointment Details';
                } else if (routeName == '/booking/review') {
                  _currentTitle = 'Write Review';
                } else if (routeName == '/offers/special') {
                  _currentTitle = 'Special Offers';
                } else if (routeName == '/payment/history') {
                  _currentTitle = 'Payment History';
                }
              }
            });
          }
        });
      }
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
    // Show FAB only on specific tabs
    switch (_currentIndex) {
      case 0: // Home - Quick booking
        return FloatingActionButton(
          onPressed: _showQuickBookingOptions,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 4,
          tooltip: 'Quick Booking',
          child: const Icon(Icons.cut_rounded, size: 28),
        );
      case 1: // Bookings - Create new booking
        return FloatingActionButton(
          onPressed: _showQuickBookingOptions,
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

  Widget _buildDrawer(
      AuthProvider authProvider, NotificationProvider notificationProvider) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          _buildDrawerHeader(authProvider),

          // Main Navigation Section
          _buildDrawerSection('Navigation', [
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => _closeDrawerAndNavigate(() => _setCurrentIndex(0)),
            ),
            _buildDrawerItem(
              icon: Icons.local_offer_rounded,
              title: 'Special Offers',
              onTap: () => _closeDrawerAndNavigate(_navigateToSpecialOffers),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'My Profile',
              onTap: () => _closeDrawerAndNavigate(
                  () => _navigateToProfile(authProvider)),
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
              title: 'Notification Settings',
              onTap: () =>
                  _closeDrawerAndNavigate(_navigateToNotificationSettings),
            ),
            _buildDrawerItem(
              icon: Icons.security,
              title: 'Privacy & Security',
              onTap: () => _closeDrawerAndNavigate(_navigateToPrivacySettings),
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
              icon: Icons.share,
              title: 'Share App',
              onTap: () => _closeDrawerAndNavigate(_shareApp),
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
        authProvider.user?.email ?? 'client@sheersync.com',
        style: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: authProvider.user?.profileImage != null
            ? NetworkImage(authProvider.user!.profileImage!)
            : null,
        child: authProvider.user?.profileImage == null
            ? Icon(Icons.person, color: AppColors.primary)
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
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.text),
      title: Text(title, style: TextStyle(color: color ?? AppColors.text)),
      onTap: onTap,
    );
  }

  // Helper method to close drawer and then execute navigation
  void _closeDrawerAndNavigate(VoidCallback navigationCallback) {
    Navigator.of(context).pop();
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

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentIndex];

    // Check if we can pop the current navigator
    if (currentNavigator.currentState?.canPop() == true) {
      currentNavigator.currentState?.pop();
      _updateTitleAfterPop();
      return false;
    }

    // If we're on the first route of the current tab, show exit confirmation
    final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit SheerSync?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;

    return shouldExit;
  }

  void _handleBackPress() {
    final currentNavigator = _navigatorKeys[_currentIndex];
    if (currentNavigator.currentState?.canPop() == true) {
      currentNavigator.currentState?.pop();
      _updateTitleAfterPop();
    } else if (!_shouldShowBottomNav()) {
      // If we're in chat screen without bottom nav, go back to messages tab
      _setCurrentIndex(2);
    }
  }

  void _updateTitleAfterPop() {
    // Schedule title update after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        ClientProfileScreen(user: authProvider.user!),
        'My Profile',
      );
    }
  }

  void _navigateToSpecialOffers() {
    _pushScreen(const SpecialOffersScreen(), 'Special Offers');
  }

  void _navigateToSettings() {
    _pushScreen(const SettingsScreen(), 'Settings');
  }

  void _navigateToNotificationSettings() {
    _pushScreen(const NotificationCenterScreen(), 'Notification Settings');
  }

  void _navigateToPrivacySettings() {
    _pushScreen(const SettingsScreen(), 'Privacy & Security');
  }

  void _navigateToPaymentHistory() {
    _pushScreen(const PaymentHistoryScreen(), 'Payment History');
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

  void _showQuickBookingOptions() {
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
                  Icon(Icons.cut_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Booking',
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
                icon: Icons.search_rounded,
                title: 'Find Professional',
                subtitle: 'Browse available barbers & stylists',
                onTap: () {
                  Navigator.pop(context);
                  _pushScreen(const SelectBarberScreen(), 'Find Professional');
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

  void _refreshBookings() {
    final authProvider = context.read<AuthProvider>();
    final appointmentsProvider = context.read<AppointmentsProvider>();

    if (authProvider.user != null) {
      appointmentsProvider.loadClientAppointments(authProvider.user!.id);
      showCustomSnackBar(
        context,
        'Refreshing bookings...',
        type: SnackBarType.success,
      );
    }
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For assistance, please contact our support team:\n\n'
          '📧 Email: daviddranoel@gmail.com.com\n'
          '📞 Phone: +264 81 288 3053\n\n'
          'We\'re here to help you with any questions or issues!',
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

  void _shareApp() {
    showCustomSnackBar(
      context,
      'Share functionality will be implemented',
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
          'Book appointments, chat with professionals, and make secure payments all in one app.\n\n'
          '© 2024 SheerSync. All rights reserved.',
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

// Route observer to track navigation changes
class _RouteObserver extends NavigatorObserver {
  final Function(Route<dynamic>?) onRouteChanged;

  _RouteObserver(this.onRouteChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(previousRoute);
  }
}