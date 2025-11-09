// lib/features/barber/marketing/marketing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class MarketingScreen extends StatefulWidget {
  final bool isClientView;
  final String? barberId;

  const MarketingScreen({
    super.key,
    this.isClientView = false,
    this.barberId,
  });

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  bool _isCreatingOffer = false;
  double _discountPercentage = 10.0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final barber = authProvider.user;

    if (widget.isClientView && widget.barberId == null) {
      return _buildErrorState('Barber information not available');
    }

    final currentBarberId = widget.isClientView ? widget.barberId! : barber?.id;

    if (currentBarberId == null) {
      return _buildErrorState('Please login again');
    }

    return Scaffold(
     
      body: widget.isClientView 
          ? _buildClientView(currentBarberId)
          : _buildBarberView(barber!),
    );
  }

  Widget _buildClientView(String barberId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header for client view
          _buildClientHeader(),
          const SizedBox(height: 24),
          
          // Active Offers for this barber
          _buildActiveOffersSection(barberId, isClientView: true),
        ],
      ),
    );
  }

  Widget _buildBarberView(dynamic barber) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Share Section
          _buildQuickShareSection(barber),
          const SizedBox(height: 24),
          
          // Create Special Offer
          _buildSpecialOfferSection(),
          const SizedBox(height: 24),
          
          // Active Offers (Real-time)
          _buildActiveOffersSection(barber.id),
          const SizedBox(height: 24),
          
          // Marketing Analytics
          _buildAnalyticsSection(barber.id),
        ],
      ),
    );
  }

  Widget _buildClientHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
              Icons.local_offer_rounded,
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
                  'Special Offers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exclusive discounts and promotions from this barber',
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

  Widget _buildQuickShareSection(dynamic barber) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your profile and services on social media',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildShareButton(
                  'Share Profile',
                  Icons.person,
                  AppColors.primary,
                  () => _shareProfile(barber),
                ),
                _buildShareButton(
                  'Share Services',
                  Icons.work,
                  AppColors.accent,
                  () => _shareServices(barber),
                ),
                _buildShareButton(
                  'Share Promo',
                  Icons.local_offer,
                  Colors.purple,
                  () => _sharePromotion(barber),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialOfferSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Special Offer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _offerController,
              decoration: const InputDecoration(
                labelText: 'Offer Title',
                hintText: 'e.g., Summer Special, New Client Discount',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Offer Description',
                hintText: 'Describe your special offer...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount: ${_discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _discountPercentage,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            _discountPercentage = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount Code',
                      hintText: 'SUMMER25',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreatingOffer ? null : _createSpecialOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isCreatingOffer
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create & Share Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOffersSection(String barberId, {bool isClientView = false}) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isClientView ? 'Available Offers' : 'Active Offers',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isClientView 
                  ? 'Special discounts and promotions available'
                  : 'Real-time tracking of your active promotions',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('marketing_offers')
                  .where('barberId', isEqualTo: barberId)
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final offers = snapshot.data!.docs;

                if (offers.isEmpty) {
                  return _buildEmptyOffersState(isClientView);
                }

                return Column(
                  children: offers.map((doc) {
                    final offer = doc.data() as Map<String, dynamic>;
                    return _buildOfferCard(offer, doc.id, isClientView: isClientView);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(String barberId) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marketing Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('marketing_analytics')
                  .where('barberId', isEqualTo: barberId)
                  .orderBy('date', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final analytics = snapshot.data!.docs;
                final stats = _calculateMarketingStats(analytics);

                return Row(
                  children: [
                    _buildAnalyticCard(
                      'Profile Shares',
                      stats['profileShares'].toString(),
                      Icons.share,
                      AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildAnalyticCard(
                      'Offer Views',
                      stats['offerViews'].toString(),
                      Icons.visibility,
                      AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _buildAnalyticCard(
                      'Redemptions',
                      stats['redemptions'].toString(),
                      Icons.local_offer,
                      Colors.green,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, String offerId, {bool isClientView = false}) {
    final isExpired = DateTime.now().millisecondsSinceEpoch > offer['expiresAt'];
    
    if (isExpired && isClientView) {
      return Container(); // Don't show expired offers to clients
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isExpired ? Colors.grey[100] : AppColors.primary.withOpacity(0.05),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isExpired ? Colors.grey : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_offer, 
            color: isExpired ? Colors.grey : AppColors.primary
          ),
        ),
        title: Text(
          offer['title'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpired ? Colors.grey : AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offer['description'],
              style: TextStyle(
                color: isExpired ? Colors.grey : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${offer['discount']}% off • Code: ${offer['discountCode']}',
              style: TextStyle(
                color: isExpired ? Colors.grey : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Valid until ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(offer['expiresAt']))}',
              style: TextStyle(
                color: isExpired ? Colors.grey : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (isExpired) 
              Text(
                'EXPIRED',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: isClientView 
            ? _buildClientOfferActions(offer)
            : _buildBarberOfferActions(offer, offerId, isExpired),
      ),
    );
  }

  Widget _buildClientOfferActions(Map<String, dynamic> offer) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${offer['discount']}% OFF',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _copyDiscountCode(offer['discountCode']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Copy Code',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarberOfferActions(Map<String, dynamic> offer, String offerId, bool isExpired) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.share, color: AppColors.primary),
          onPressed: () => _shareExistingOffer(offer),
        ),
        IconButton(
          icon: Icon(
            isExpired ? Icons.delete_forever : Icons.delete,
            color: isExpired ? Colors.grey : AppColors.error,
          ),
          onPressed: isExpired ? null : () => _deactivateOffer(offerId),
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOffersState(bool isClientView) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined, 
            size: 48, 
            color: AppColors.textSecondary
          ),
          const SizedBox(height: 12),
          Text(
            isClientView ? 'No Current Offers' : 'No Active Offers',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isClientView 
                ? 'Check back later for special promotions'
                : 'Create your first special offer to attract more clients',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // Marketing Functions
  Future<void> _shareProfile(dynamic barber) async {
    try {
      final shareText =  '''💈 Discover ${barber.fullName} on VerveBook!  
        Expert ${barber.userType} delivering quality
        grooming services.  

        📅 Book your next appointment easily
        via the SheerSync app.  

        #SheerSync #Barber #Style
        ''';

      await Share.share(shareText);
      
      // Track the share event
      await _trackMarketingEvent(barber.id, 'profile_share');
      
      showCustomSnackBar(context, 'Profile shared successfully!', type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share profile: $e', type: SnackBarType.error);
    }
  }

  Future<void> _shareServices(dynamic barber) async {
    try {
      final servicesSnapshot = await _firestore
          .collection('services')
          .where('barberId', isEqualTo: barber.id)
          .where('isActive', isEqualTo: true)
          .get();

      final services = servicesSnapshot.docs;
      if (services.isEmpty) {
        showCustomSnackBar(context, 'No services available to share', type: SnackBarType.warning);
        return;
      }

      String servicesText = 'Services by ${barber.fullName}:\n\n';
      for (final service in services) {
        final data = service.data();
        servicesText += '• ${data['name']} - N\$${data['price']}\n';
      }
      
      servicesText += '\n📱 Book now on VerveBook! #${barber.role}Services';

      await Share.share(servicesText);
      await _trackMarketingEvent(barber.id, 'services_share');
      
      showCustomSnackBar(context, 'Services shared successfully!', type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share services: $e', type: SnackBarType.error);
    }
  }

  Future<void> _sharePromotion(dynamic barber) async {
    try {
      final shareText = '''
      🎉 ${barber.fullName} Special Offer! 🎉

      - Premium barber services at great deals
      - Highly rated, professional service
      - Limited-time promotion

      📱 Book now via the VerveBook app

      #BarberPromo #SheerSync #Haircare
      ''';

      await Share.share(shareText);
      await _trackMarketingEvent(barber.id, 'promotion_share');
      
      showCustomSnackBar(context, 'Promotion shared successfully!', type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share promotion: $e', type: SnackBarType.error);
    }
  }

  Future<void> _createSpecialOffer() async {
    if (_offerController.text.isEmpty || _discountController.text.isEmpty) {
      showCustomSnackBar(context, 'Please fill all required fields', type: SnackBarType.warning);
      return;
    }

    setState(() {
      _isCreatingOffer = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final barber = authProvider.user!;

      final offerData = {
        'id': 'offer_${DateTime.now().millisecondsSinceEpoch}',
        'barberId': barber.id,
        'barberName': barber.fullName,
        'title': _offerController.text.trim(),
        'description': _messageController.text.trim(),
        'discount': _discountPercentage,
        'discountCode': _discountController.text.trim().toUpperCase(),
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        'redemptionCount': 0,
      };

      await _firestore
          .collection('marketing_offers')
          .doc(offerData['id'] as String?)
          .set(offerData);

      // Share the offer immediately
      final shareText = '''
🎁 SPECIAL OFFER from ${barber.fullName}! 🎁

${offerData['title']}

${offerData['description']}

💰 ${offerData['discount']}% OFF
🎫 Use code: ${offerData['discountCode']}

📱 Book now on SheerSync app!
Valid until ${DateFormat('MMM d, yyyy').format(DateTime.now().add(const Duration(days: 30)))}

#SpecialOffer #BarberDeal #SheerSync
''';

      await Share.share(shareText);
      await _trackMarketingEvent(barber.id, 'offer_created');

      // Clear form
      _offerController.clear();
      _messageController.clear();
      _discountController.clear();
      setState(() {
        _discountPercentage = 10.0;
      });

      showCustomSnackBar(context, 'Offer created and shared successfully!', type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to create offer: $e', type: SnackBarType.error);
    } finally {
      setState(() {
        _isCreatingOffer = false;
      });
    }
  }

  Future<void> _shareExistingOffer(Map<String, dynamic> offer) async {
    try {
      final shareText = '''
🎁 SPECIAL OFFER! 🎁

${offer['title']}

${offer['description']}

💰 ${offer['discount']}% OFF
🎫 Use code: ${offer['discountCode']}

📱 Book now on SheerSync app!
Valid until ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(offer['expiresAt']))}

#SpecialOffer #BarberDeal #SheerSync
''';

      await Share.share(shareText);
      await _trackMarketingEvent(offer['barberId'], 'offer_shared');
      
      showCustomSnackBar(context, 'Offer shared successfully!', type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share offer: $e', type: SnackBarType.error);
    }
  }

  Future<void> _deactivateOffer(String offerId) async {
    try {
      await _firestore
          .collection('marketing_offers')
          .doc(offerId)
          .update({'isActive': false});
      
      showCustomSnackBar(context, 'Offer deactivated', type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to deactivate offer: $e', type: SnackBarType.error);
    }
  }

  Future<void> _copyDiscountCode(String code) async {
    // You would typically use clipboard functionality here
    // For now, we'll show a snackbar
    showCustomSnackBar(
      context, 
      'Discount code "$code" copied! Use it during booking.',
      type: SnackBarType.success,
    );
  }

  Future<void> _trackMarketingEvent(String barberId, String eventType) async {
    try {
      await _firestore.collection('marketing_analytics').add({
        'barberId': barberId,
        'eventType': eventType,
        'date': DateTime.now().millisecondsSinceEpoch,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking marketing event: $e');
    }
  }

  Map<String, int> _calculateMarketingStats(List<QueryDocumentSnapshot> analytics) {
    int profileShares = 0;
    int offerViews = 0;
    int redemptions = 0;

    for (final doc in analytics) {
      final data = doc.data() as Map<String, dynamic>;
      switch (data['eventType']) {
        case 'profile_share':
          profileShares++;
          break;
        case 'offer_created':
        case 'offer_shared':
          offerViews++;
          break;
        case 'offer_redeemed':
          redemptions++;
          break;
      }
    }

    return {
      'profileShares': profileShares,
      'offerViews': offerViews,
      'redemptions': redemptions,
    };
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Unable to Load',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _offerController.dispose();
    _discountController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}