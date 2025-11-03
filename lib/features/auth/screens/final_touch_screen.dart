import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_provider.dart';
import 'package:sheersync/features/client/client_shell.dart';
import 'package:sheersync/features/barber/barber_shell.dart';
import 'package:sheersync/core/constants/colors.dart'; // ADD THIS IMPORT

class FinalTouchScreen extends StatefulWidget {
  const FinalTouchScreen({super.key});

  @override
  State<FinalTouchScreen> createState() => _FinalTouchScreenState();
}

class _FinalTouchScreenState extends State<FinalTouchScreen> {
  bool _isLoading = false;

  Future<void> _proceedToApp() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Add a small delay to show the loading state
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      // Navigate based on user type
      if (authProvider.user?.userType == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientShell(),
          ),
        );
      } else {
        // Both barber and hairstylist go to barber shell
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BarberShell(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userType = authProvider.user?.userType ?? 'client';

    return Scaffold(
      backgroundColor: AppColors.background, // UPDATE: Use theme background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              
              // Success Illustration
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1), // UPDATE: Use primary color with opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.primary, // UPDATE: Use primary color
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'Welcome to SheerSync! 🎉',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text, // UPDATE: Use theme text color
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Your account has been successfully verified and created.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, // UPDATE: Use secondary text color
                ),
              ),
              
              const SizedBox(height: 24),
              
              // User Type Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight, // UPDATE: Use surface color
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border), // UPDATE: Use border color
                ),
                child: Column(
                  children: [
                    Icon(
                      userType == 'client' 
                          ? Icons.person
                          : userType == 'barber'
                              ? Icons.content_cut
                              : Icons.style,
                      size: 40,
                      color: AppColors.accent, // UPDATE: Use accent color
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userType == 'client' 
                          ? 'Client Account'
                          : userType == 'barber'
                              ? 'Barber Account'
                              : 'Hairstylist Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text, // UPDATE: Use theme text color
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userType == 'client'
                          ? 'You can now book appointments with professional barbers and hairstylists.'
                          : 'You can now manage your appointments, clients, and earnings.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary, // UPDATE: Use secondary text color
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _proceedToApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // UPDATE: Use primary color
                    foregroundColor: AppColors.onPrimary, // UPDATE: Use onPrimary color
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.onPrimary), // UPDATE: Use onPrimary color
                          ),
                        )
                      : Text(
                          'Get Started',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary, // UPDATE: Use onPrimary color
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}