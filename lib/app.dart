import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/theme/app_theme.dart';
import 'features/auth/auth_wrapper.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/settings_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Student Barber App',
            theme: settingsProvider.settings.isDarkMode 
                ? AppTheme.darkTheme 
                : AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}