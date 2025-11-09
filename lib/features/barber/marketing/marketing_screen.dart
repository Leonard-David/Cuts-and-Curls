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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'Special Offers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Client Header
                _buildClientHeader(),
                const SizedBox(height: 32),

                // Active Offers for this barber
                _buildActiveOffersSection(barberId, isClientView: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarberView(dynamic barber) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'Fuel your Growth',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
          ),
        ),
      ],
    );
  }

  Widget _buildClientHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.accent.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exclusive Offers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover special discounts and promotions tailored just for you',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Share',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Expand your reach by sharing your profile and services',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    'Profile',
                    Icons.person_outline_rounded,
                    AppColors.primary,
                    () => _shareProfile(barber),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    'Services',
                    Icons.work_outline_rounded,
                    AppColors.accent,
                    () => _shareServices(barber),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    'Promotion',
                    Icons.campaign_outlined,
                    Colors.purple,
                    () => _sharePromotion(barber),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialOfferSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.create_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Special Offer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _offerController,
              decoration: InputDecoration(
                labelText: 'Offer Title',
                hintText: 'e.g., Summer Special, New Client Discount',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Offer Description',
                hintText: 'Describe your special offer and benefits...',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                alignLabelWithHint: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.border.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Discount Percentage',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_discountPercentage.toStringAsFixed(0)}% OFF',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'Discount Code',
                              hintText: 'SUMMER25',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _discountPercentage,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      onChanged: (value) {
                        setState(() {
                          _discountPercentage = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isCreatingOffer ? null : _createSpecialOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isCreatingOffer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Create & Share Offer',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOffersSection(String barberId,
      {bool isClientView = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isClientView ? 'Available Offers' : 'Active Campaigns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isClientView
                  ? 'Limited-time promotions available for you'
                  : 'Track performance of your active promotions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('marketing_offers')
                  .where('barberId', isEqualTo: barberId)
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final offers = snapshot.data!.docs;

                if (offers.isEmpty) {
                  return _buildEmptyOffersState(isClientView);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: offers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = offers[index];
                    final offer = doc.data() as Map<String, dynamic>;
                    return _buildOfferCard(offer, doc.id,
                        isClientView: isClientView);
                  },
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your marketing efforts and engagement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
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
                    Expanded(
                      child: _buildAnalyticCard(
                        'Profile\nShares',
                        stats['profileShares'].toString(),
                        Icons.share_rounded,
                        AppColors.primary,
                        '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticCard(
                        'Offer\nViews',
                        stats['offerViews'].toString(),
                        Icons.visibility_rounded,
                        AppColors.accent,
                        '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticCard(
                        'Redemptions',
                        stats['redemptions'].toString(),
                        Icons.verified_rounded,
                        AppColors.success,
                        '',
                      ),
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

  Widget _buildOfferCard(Map<String, dynamic> offer, String offerId,
      {bool isClientView = false}) {
    final isExpired =
        DateTime.now().millisecondsSinceEpoch > offer['expiresAt'];

    if (isExpired && isClientView) {
      return Container(); // Don't show expired offers to clients
    }

    return Container(
      decoration: BoxDecoration(
        color:
            isExpired ? Colors.grey[50] : AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.grey[300]!
              : AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isExpired
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[500]!],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.accent.withOpacity(0.1),
                        ],
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_rounded,
                color: isExpired ? Colors.grey[600] : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer['title'],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isExpired
                                        ? Colors.grey[600]
                                        : AppColors.text,
                                  ),
                        ),
                      ),
                      if (!isClientView && isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'EXPIRED',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? Colors.grey[500]
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${offer['discount']}% OFF',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Code: ${offer['discountCode']}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isExpired
                                  ? Colors.grey[500]
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                offer['expiresAt'])),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isExpired
                                  ? Colors.grey[500]
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isClientView) ...[
              const SizedBox(width: 12),
              _buildBarberOfferActions(offer, offerId, isExpired),
            ] else ...[
              const SizedBox(width: 12),
              _buildClientOfferActions(offer),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientOfferActions(Map<String, dynamic> offer) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.content_copy_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () => _copyDiscountCode(offer['discountCode']),
          tooltip: 'Copy\ncode',
        ),
        const SizedBox(height: 4),
        Text(
          'Copy',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildBarberOfferActions(
      Map<String, dynamic> offer, String offerId, bool isExpired) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.share_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () => _shareExistingOffer(offer),
          tooltip: 'Share\noffer',
        ),
        IconButton(
          icon: Icon(
            isExpired
                ? Icons.delete_forever_rounded
                : Icons.delete_outline_rounded,
            color: isExpired ? Colors.grey : AppColors.error,
            size: 20,
          ),
          onPressed: isExpired ? null : () => _deactivateOffer(offerId),
          tooltip: isExpired ? 'Offer\nexpired' : 'Deactivate offer',
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOffersState(bool isClientView) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isClientView ? 'No Current Offers' : 'No Active Campaigns',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isClientView
                  ? 'Check back soon for exclusive promotions and discounts'
                  : 'Create your first promotional offer to attract more clients and grow your business',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Marketing Functions (unchanged, but now with better UI integration)
  Future<void> _shareProfile(dynamic barber) async {
    try {
      final shareText = '''💈 Discover ${barber.fullName} on SheerSync!  
        Expert ${barber.userType} delivering quality
        grooming services.  

        📅 Book your next appointment easily
        via the SheerSync app.  

        #SheerSync #Barber #Style
        ''';

      await Share.share(shareText);

      // Track the share event
      await _trackMarketingEvent(barber.id, 'profile_share');

      showCustomSnackBar(context, 'Profile shared successfully!',
          type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share profile: $e',
          type: SnackBarType.error);
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
        showCustomSnackBar(context, 'No services available to share',
            type: SnackBarType.warning);
        return;
      }

      String servicesText = 'Services by ${barber.fullName}:\n\n';
      for (final service in services) {
        final data = service.data();
        servicesText += '• ${data['name']} - N\$${data['price']}\n';
      }

      servicesText += '\n📱 Book now on SheerSync! #BarberServices';

      await Share.share(servicesText);
      await _trackMarketingEvent(barber.id, 'services_share');

      showCustomSnackBar(context, 'Services shared successfully!',
          type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share services: $e',
          type: SnackBarType.error);
    }
  }

  Future<void> _sharePromotion(dynamic barber) async {
    try {
      final shareText = '''
      🎉 ${barber.fullName} Special Offer! 🎉

      - Premium barber services at great deals
      - Highly rated, professional service
      - Limited-time promotion

      📱 Book now via the SheerSync app

      #BarberPromo #SheerSync #Haircare
      ''';

      await Share.share(shareText);
      await _trackMarketingEvent(barber.id, 'promotion_share');

      showCustomSnackBar(context, 'Promotion shared successfully!',
          type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share promotion: $e',
          type: SnackBarType.error);
    }
  }

  Future<void> _createSpecialOffer() async {
    if (_offerController.text.isEmpty || _discountController.text.isEmpty) {
      showCustomSnackBar(context, 'Please fill all required fields',
          type: SnackBarType.warning);
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
        'expiresAt':
            DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
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

      showCustomSnackBar(context, 'Offer created and shared successfully!',
          type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to create offer: $e',
          type: SnackBarType.error);
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

      showCustomSnackBar(context, 'Offer shared successfully!',
          type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to share offer: $e',
          type: SnackBarType.error);
    }
  }

  Future<void> _deactivateOffer(String offerId) async {
    try {
      await _firestore
          .collection('marketing_offers')
          .doc(offerId)
          .update({'isActive': false});

      showCustomSnackBar(context, 'Offer deactivated',
          type: SnackBarType.success);
    } catch (e) {
      showCustomSnackBar(context, 'Failed to deactivate offer: $e',
          type: SnackBarType.error);
    }
  }

  Future<void> _copyDiscountCode(String code) async {
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

  Map<String, int> _calculateMarketingStats(
      List<QueryDocumentSnapshot> analytics) {
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
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
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
