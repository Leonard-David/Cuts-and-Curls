import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_provider.dart';
import 'final_touch_screen.dart';
import 'package:sheersync/core/constants/colors.dart'; // ADD THIS IMPORT

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVerified = await authProvider.checkEmailVerification();

    if (isVerified && mounted) {
      // Navigate to final touch screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const FinalTouchScreen(),
        ),
      );
    } else {
      setState(() {
        _isChecking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email not verified yet. Please check your inbox.'),
          backgroundColor: AppColors.error, // UPDATE: Use error color
        ),
      );
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isResending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationEmail();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent successfully!'),
          backgroundColor: AppColors.success, // UPDATE: Use success color
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to resend email'),
          backgroundColor: AppColors.error, // UPDATE: Use error color
        ),
      );
    }

    setState(() {
      _isResending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // UPDATE: Use theme background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              
              // Illustration
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1), // UPDATE: Use primary color with opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: AppColors.primary, // UPDATE: Use primary color
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text, // UPDATE: Use theme text color
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'We\'ve sent a verification link to your email address.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, // UPDATE: Use secondary text color
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Please check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, // UPDATE: Use secondary text color
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Check Verification Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // UPDATE: Use primary color
                    foregroundColor: AppColors.onPrimary, // UPDATE: Use onPrimary color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // UPDATE: Match theme border radius
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.onPrimary), // UPDATE: Use onPrimary color
                          ),
                        )
                      : Text(
                          'I\'ve Verified My Email',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary, // UPDATE: Use onPrimary color
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Resend Email Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isResending ? null : _resendVerification,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary, // UPDATE: Use primary color
                    side: BorderSide(color: AppColors.primary), // UPDATE: Use primary color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // UPDATE: Match theme border radius
                    ),
                  ),
                  child: _isResending
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary), // UPDATE: Use primary color
                          ),
                        )
                      : Text(
                          'Resend Verification Email',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary, // UPDATE: Use primary color
                          ),
                        ),
                ),
              ),
              
              const Spacer(),
              
              // Help Text
              Text(
                'Didn\'t receive the email? Check your spam folder or try resending.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary, // UPDATE: Use secondary text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}