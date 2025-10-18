import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class LoaderScreen extends StatelessWidget {
  const LoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/images/logo/logo.png', height: 100),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Loading your experience...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
