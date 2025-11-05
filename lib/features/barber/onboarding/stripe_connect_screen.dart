// lib/features/barber/onboarding/stripe_connect_screen.dart
// Stripe Connect onboarding for barbers to receive payments

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/utils/stripe_helper.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/features/auth/controllers/auth_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StripeConnectScreen extends StatefulWidget {
  const StripeConnectScreen({super.key});

  @override
  State<StripeConnectScreen> createState() => _StripeConnectScreenState();
}

class _StripeConnectScreenState extends State<StripeConnectScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Connect Payment Account'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
        body: const Center(
          child: Text('Please login to set up payments'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Payment Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Information
          _buildHeaderSection(user.fullName),
          
          if (_isOnboarding)
            Expanded(
              child: WebViewWidget(
                controller: _webViewController,
              ),
            )
          else
            _buildOnboardingStartSection(user),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(String barberName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
        ]),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payment_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Setup for $barberName',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect your bank account to start receiving payments securely',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStartSection(dynamic user) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Security Badge
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_rounded,
                size: 60,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            
            // Benefits List
            _buildBenefitItem(
              Icons.credit_card_rounded,
              'Secure Payments',
              'All transactions are PCI-compliant and encrypted',
            ),
            _buildBenefitItem(
              Icons.schedule_rounded,
              'Fast Transfers',
              'Receive payments directly to your bank account',
            ),
            _buildBenefitItem(
              Icons.visibility_off_rounded,
              'Privacy Protected',
              'Only masked card details are stored',
            ),
            _buildBenefitItem(
              Icons.receipt_long_rounded,
              'Automatic Records',
              'Complete payment history and tax documentation',
            ),
            
            const SizedBox(height: 32),
            
            // Start Onboarding Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _startOnboardingProcess(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
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
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Connect Stripe Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Security Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Powered by Stripe - Industry-leading security and compliance',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startOnboardingProcess(dynamic user) async {
    setState(() {
      _isLoading = true;
      _isOnboarding = true;
    });

    // Initialize WebViewController
    _initializeWebViewController(user);
  }

  void _initializeWebViewController(dynamic user) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            
            // Check if onboarding is complete
            if (url.contains('return_url') || url.contains('success')) {
              _handleOnboardingCompletion(user);
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
            _handleWebViewError(error, user);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            // Monitor URL changes for completion detection
            if (change.url != null && 
                (change.url!.contains('return_url') || change.url!.contains('success'))) {
              _handleOnboardingCompletion(user);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('about:blank'));

    // Start Stripe onboarding after WebView is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStripeOnboarding(user);
    });
  }

  Future<void> _startStripeOnboarding(dynamic user) async {
    try {
      // Create Stripe Connect account
      final account = await StripeHelper.createConnectAccount(
        email: user.email,
        country: 'US', // You can make this dynamic based on user location
      );

      // Generate onboarding URL
      final accountLink = await StripeHelper.createAccountLink(
        accountId: account['id'],
        refreshUrl: 'https://yourapp.com/refresh', // Your refresh URL
        returnUrl: 'https://yourapp.com/success', // Your return URL
      );

      // Load the onboarding URL in WebView
      final onboardingUrl = accountLink['url'];
      if (onboardingUrl != null && onboardingUrl.isNotEmpty) {
        await _webViewController.loadRequest(Uri.parse(onboardingUrl));
      } else {
        throw Exception('Invalid onboarding URL');
      }
      
      // Store Stripe account ID in user profile
      await _updateUserStripeAccount(user.id, account['id']);
      
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Failed to start onboarding: $e',
          type: SnackBarType.error,
        );
        setState(() {
          _isLoading = false;
          _isOnboarding = false;
        });
      }
    }
  }

  void _handleWebViewError(WebResourceError error, dynamic user) {
    if (mounted) {
      showCustomSnackBar(
        context,
        'WebView Error: ${error.description}',
        type: SnackBarType.error,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOnboardingCompletion(dynamic user) async {
    try {
      // Add a small delay to ensure Stripe has processed the onboarding
      await Future.delayed(const Duration(seconds: 2));

      // Verify Stripe account status
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
      final stripeAccountId = userDoc.data()?['stripeAccountId'];
      
      if (stripeAccountId != null) {
        final accountStatus = await StripeHelper.isAccountVerified(stripeAccountId);
        
        // Mark user as Stripe verified
        await _updateUserStripeStatus(user.id, accountStatus);
        
        if (mounted) {
          showCustomSnackBar(
            context,
            accountStatus 
              ? 'Payment account connected successfully!' 
              : 'Account setup in progress. Some features may be limited until verification is complete.',
            type: accountStatus ? SnackBarType.success : SnackBarType.info,
          );
          
          Navigator.pop(context);
        }
      } else {
        throw Exception('Stripe account ID not found');
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Onboarding completion error: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _updateUserStripeAccount(String userId, String stripeAccountId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'stripeAccountId': stripeAccountId,
      'stripeConnected': false, // Will be set to true after onboarding completion
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _updateUserStripeStatus(String userId, bool isConnected) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'stripeConnected': isConnected,
      'paymentSetupCompleted': true,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}